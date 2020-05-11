# frozen_string_literal: true

module Spandx
  module Core
    class DataFile
      attr_reader :absolute_path

      def initialize(absolute_path)
        @absolute_path = Pathname.new(absolute_path)
        FileUtils.mkdir_p(@absolute_path.dirname)
      end

      def each
        return unless exist?

        open_file do |io|
          while (line = io.gets)
            yield parse_row(line)
          end
        end
      end

      def search(name:, version:)
        open_file do |io|
          search_for("#{name}-#{version}", io, index.data)
        end
      end

      def insert(name, version, licenses)
        return if [name, version].any? { |x| x.nil? || x.empty? }

        open_file(mode: 'a') do |io|
          io.write(to_csv([name, version, licenses.join('-|-')]))
        end
      end

      def exist?
        absolute_path.exist?
      end

      def open_file(mode: 'rb')
        absolute_path.open(mode) { |io| yield io }
      rescue EOFError => error
        Spandx.logger.error(error)
        nil
      rescue Errno::ENOENT => error
        Spandx.logger.error(error)
        nil
      end

      def index
        @index ||= IndexFile.new(self)
      end

      private

      def search_for(term, io, lines)
        return if lines.empty?

        mid = lines.size == 1 ? 0 : lines.size / 2
        io.seek(lines[mid])
        comparison = matches?(term, parse_row(io.readline)) do |row|
          return row
        end

        search_for(term, io, partition(comparison, mid, lines))
      end

      def matches?(term, row)
        (term <=> "#{row[0]}-#{row[1]}").tap { |x| yield row if x.zero? }
      end

      def parse_row(line)
        CsvParser.parse(line)
      end

      def partition(comparison, mid, lines)
        min, max = comparison.positive? ? [mid + 1, lines.size] : [0, mid]
        lines.slice(min, max)
      end

      def to_csv(array)
        array.to_csv(force_quotes: true)
      end
    end
  end
end
