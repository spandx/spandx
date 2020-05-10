# frozen_string_literal: true

module Spandx
  module Core
    class IndexFile
      attr_reader :data_file, :path

      def initialize(data_file)
        @data_file = data_file
        @path = Pathname.new("#{data_file.absolute_path}.lines")
      end

      def each
        data.each do |position|
          yield position
        end
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

      def update!
        return unless data_file.exist?

        sort(data_file)
        rebuild_index!
      end

      private

      def sort(data_file)
        data_file.absolute_path.write(data_file.absolute_path.readlines.sort.uniq.join)
      end

      def rebuild_index!
        data_file.open_file do |io|
          lines = lines_in(io)
          path.write(lines.map(&:to_s).join(','))
          @data = lines
        end
      end

      def data
        @data ||= load
      end

      def load
        if path.exist?
          FastestCSV.parse_line(path.read).map(&:to_i)
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
