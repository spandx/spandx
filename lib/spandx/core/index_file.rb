# frozen_string_literal: true

module Spandx
  module Core
    class IndexFile
      attr_reader :data_file, :path

      def initialize(data_file)
        @data_file = data_file
        @path = Pathname.new("#{data_file.absolute_path}.lines")
      end

      def size
        data.size
      end

      def empty?
        data.empty?
      end

      def [](index)
        data[index]
      end

      def slice(min, max)
        data.slice(min, max)
      end

      def index!
        data_file.absolute_path.write(data_file.absolute_path.readlines.sort.uniq.join)
        data_file.absolute_path.open(mode: 'r') do |io|
          path.write(JSON.generate(lines_in(io)))
        end
      end

      private

      def data
        @data ||=
          if path.exist?
            FastestCSV.parse_line(path.read)
          else
            data_file.open_file { |io| lines_in(io) }
          end
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
