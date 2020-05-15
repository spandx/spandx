# frozen_string_literal: true

module Spandx
  module Core
    class IndexFile
      UINT_32_DIRECTIVE = 'V'
      UINT_32_SIZE = 4

      attr_reader :data_file, :path

      def initialize(data_file)
        @data_file = data_file
        @path = Pathname.new("#{data_file.absolute_path}.idx")
        @entries = {}
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
            return row if comparison.zero?

            if comparison.positive?
              min = mid + 1
            else
              max = mid
            end
          end
        end
      end

      def size
         path.exist? ? path.size / UINT_32_SIZE : (data&.size || 0)
      end

      def position_for(row_number)
        data.fetch(row_number)

        # @entries.fetch(row_number) do |key|
        # offset = row_number * 2
        # @entries[key] = IO.read(path, 2, offset, mode: 'rb').unpack1('v')

        # #@entries[key] = File.open(path, mode: 'rb') do |io|
        # #io.seek(row_number * 2)
        # #io.read(2).unpack1('v')
        # #end
        # end
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
          File.open(path, mode: 'wb') do |index_io|
            lines_in(data_io).each do |pos|
              index_io.write([pos].pack(UINT_32_DIRECTIVE))
            end
          end
        end
      end

      def load
        return build_index_from_data_file unless path.exist?

        [].tap do |items|
          each_index do |position|
            items << position
          end
        end
      end

      def build_index_from_data_file
        data_file.open_file { |io| lines_in(io) }
      end

      def each_index
        File.open(path, mode: 'rb') do |io|
          yield io.read(UINT_32_SIZE).unpack1(UINT_32_DIRECTIVE) until io.eof?
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
