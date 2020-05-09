# frozen_string_literal: true

module Spandx
  module Core
    class Datafile
      attr_reader :absolute_path

      def initialize(absolute_path)
        @absolute_path = absolute_path
      end

      def each
        return unless exist?

        CSV.open(absolute_path, 'r') { |io| yield io.gets until io.eof? }
      end

      def search(name:, version:)
        open_file do |io|
          search_for("#{name}-#{version}", io, index_for(io))
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

        IO.write(absolute_path, IO.readlines(absolute_path).sort.uniq.join)
        File.open(absolute_path, mode: 'r') do |io|
          IO.write("#{absolute_path}.lines", JSON.generate(lines_in(io)))
        end
      end

      private

      def exist?
        File.exist?(absolute_path)
      end

      def open_file(mode: 'r')
        FileUtils.mkdir_p(File.dirname(absolute_path)) if mode != 'r'
        File.open(absolute_path, mode) { |io| yield io }
      rescue EOFError
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

      def index_for(io)
        index_path = "#{io.path}.lines"
        File.exist?(index_path) ? JSON.parse(IO.read(index_path)) : lines_in(io)
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
