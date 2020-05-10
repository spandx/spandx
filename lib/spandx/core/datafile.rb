# frozen_string_literal: true

module Spandx
  module Core
    class Datafile
      attr_reader :absolute_path

      def initialize(absolute_path)
        @absolute_path = Pathname.new(absolute_path)
        FileUtils.mkdir_p(@absolute_path.dirname)
      end

      def each
        return unless exist?

        open_file do |io|
          loop { yield parse_row(io) }
        end
      end

      def search(name:, version:)
        open_file do |io|
          search_for("#{name}-#{version}", io, index)
        end
      end

      def insert(name, version, licenses)
        return if [name, version].any? { |x| x.nil? || x.empty? }

        open_file(mode: 'a') do |io|
          io.write(to_csv([name, version, licenses.join('-|-')]))
        end
      end

      def to_csv(array)
        array.to_csv(force_quotes: true)
      end

      def index!
        return unless exist?

        index.index!
      end

      def open_file(mode: 'r')
        absolute_path.open(mode) { |io| yield io }
      rescue EOFError => error
        Spandx.logger.error(error)
        nil
      rescue Errno::ENOENT => error
        Spandx.logger.error(error)
        nil
      end

      private

      def index
        @index ||= IndexFile.new(self)
      end

      def exist?
        absolute_path.exist?
      end

      def search_for(term, io, lines)
        return if lines.empty?

        mid = lines.size == 1 ? 0 : lines.size / 2
        io.seek(lines[mid].to_i)
        comparison = matches?(term, parse_row(io)) do |row|
          return row
        end

        search_for(term, io, partition(comparison, mid, lines))
      end

      def matches?(term, row)
        (term <=> "#{row[0]}-#{row[1]}").tap { |x| yield row if x.zero? }
      end

      def parse_row(io)
        FastestCSV.parse_line(io.readline)
      end

      def partition(comparison, mid, lines)
        min, max = comparison.positive? ? [mid + 1, lines.size] : [0, mid]
        lines.slice(min, max)
      end
    end
  end
end
