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

      def search
        min = 0
        max = size

        scan do |reader|
          until min >= max
            mid = (max - min) == 1 ? min : (((max - min) / 2) + min)
            row = reader.row(mid)
            return if row.nil? || row.empty?

            comparison = yield row

            case
            when comparison == 0
              return row
            when comparison > 0
              min = mid + 1
            else
              max = mid
            end
          end
        end
      end

      def size
        data&.size || 0
      end

      def position_for(row_number)
        data[row_number]
      end

      def scan
        data_file.open_file(mode: 'rb') do |io|
          yield Relation.new(io, self)
        end
      end

      def update!
        return unless data_file.exist?

        sort(data_file)
        rebuild_index!
      end

      private

      def data
        @data ||= load
      end

      def sort(data_file)
        data_file.absolute_path.write(data_file.absolute_path.readlines.sort.uniq.join)
      end

      def rebuild_index!
        data_file.open_file do |data_io|
          File.open(path, mode: 'w') do |index_io|
            lines_in(data_io).each_with_index do |line, index|
              index_io.pwrite([line].pack('v'), index * 2)
            end
          end
        end
      end

      def load
        return build_index_from_data_file unless path.exist?

        load_index_file
      end

      def build_index_from_data_file
        data_file.open_file { |io| lines_in(io) }
      end

      def load_index_file
        [].tap do |items|
          File.open(path, mode: 'rb') do |io|
            items << io.read(2).unpack1('v') until io.eof?
          end
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
