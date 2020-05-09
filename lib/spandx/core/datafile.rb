# frozen_string_literal: true

module Spandx
  module Core
    class Datafile
      attr_reader :absolute_path, :index_path

      def initialize(absolute_path)
        @absolute_path = Pathname.new(absolute_path)
        @index_path = Pathname.new("#{@absolute_path}.lines")
        FileUtils.mkdir_p(@absolute_path.dirname)
      end

      def each
        return unless exist?

        open_file do |io|
          yield parse_row(io)
        end
      end

      def search(name:, version:)
        open_file do |io|
          search_for("#{name}-#{version}", io, index)
        end
      rescue Errno::ENOENT => error
        Spandx.logger.error(error)
        nil
      end

      def insert(name, version, licenses)
        return if [name, version].any? { |x| x.nil? || x.empty? }

        open_file(mode: 'a') do |io|
          io.write(CSV.generate_line([name, version, licenses.join('-|-')], force_quotes: true))
        end
      end

      def index!
        return unless exist?

        absolute_path.write(absolute_path.readlines.sort.uniq.join)
        absolute_path.open(mode: 'r') do |io|
          index_path.write(JSON.generate(lines_in(io)))
        end
      end

      private

      def index
        @index ||=
          if index_path.exist?
            JSON.parse(index_path.read)
          else
            open_file { |io| lines_in(io) }
          end
      end

      def exist?
        absolute_path.exist?
      end

      def open_file(mode: 'r')
        absolute_path.open(mode) { |io| yield io }
      rescue EOFError => error
        Spandx.logger.error(error)
      end

      def search_for(term, io, lines)
        return if lines.empty?

        mid = lines.size == 1 ? 0 : lines.size / 2
        io.seek(lines[mid])
        comparison = matches?(term, parse_row(io)) do |row|
          return row
        end

        search_for(term, io, partition(comparison, mid, lines))
      end

      def matches?(term, row)
        (term <=> "#{row[0]}-#{row[1]}").tap { |x| yield row if x.zero? }
      end

      def parse_row(io)
        CSV.parse(io.readline)[0]
      end

      def partition(comparison, mid, lines)
        min, max = comparison.positive? ? [mid + 1, lines.length] : [0, mid]
        lines.slice(min, max)
      end

      def lines_in(io)
        lines = [0]
        io.seek(0)
        lines << io.pos while io.gets
        lines.pop if lines.size > 1
        lines
      end
    end
  end
end
