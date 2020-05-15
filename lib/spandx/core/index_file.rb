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
        @entries = size.positive? ? Array.new(size) : []
      end

      def each
        total = path.size / UINT_32_SIZE
        total.times do |n|
          yield position_for(n)
        end
      end

      def search(min: 0, max: size)
        scan do |reader|
          until min >= max
            mid = mid_for(min, max)
            row = reader.row(mid)
            comparison = yield row
            return row if comparison.zero?

            comparison.positive? ? (min = mid + 1) : (max = mid)
          end
        end
      end

      def size
        path.exist? ? path.size / UINT_32_SIZE : 0
      end

      def position_for(row_number)
        return if row_number > size

        entry = entries[row_number]
        return entry if entry

        bytes = IO.binread(path, UINT_32_SIZE, offset_for(row_number))
        entry = bytes.unpack1(UINT_32_DIRECTIVE)
        entries[row_number] = entry
        entry
      end

      def update!
        return unless data_file.exist?

        sort(data_file)
        rebuild_index!
      end

      private

      attr_reader :entries

      def scan
        data_file.open_file(mode: 'rb') do |io|
          yield Relation.new(io, self)
        end
      end

      def offset_for(row_number)
        row_number * UINT_32_SIZE
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

      def lines_in(io)
        lines = [0]
        io.seek(0)
        lines << io.pos while io.gets
        lines.pop if lines.size > 1
        lines
      end

      def mid_for(min, max)
        (max - min) == 1 ? min : (((max - min) / 2) + min)
      end
    end
  end
end
