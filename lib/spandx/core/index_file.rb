# frozen_string_literal: true

module Spandx
  module Core
    class IndexFile
      attr_reader :data_file, :path

      def initialize(data_file)
        @data_file = data_file
        @path = Pathname.new("#{data_file.absolute_path}.lines")
      end

      def data
        @data ||= load
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
        data_file.open_file do |data_io|
          Zlib::GzipWriter.open(path) do |index_io|
            lines_in(data_io).each do |line|
              index_io.write([line].pack('v'))
            end
          end
        end
      end

      def load
        return data_file.open_file { |io| lines_in(io) } unless path.exist?

        [].tap do |items|
          Zlib::GzipReader.open(path) do |io|
            items << io.read(2).unpack1('v') until io.eof?
          end
        end
      rescue Zlib::GzipFile::Error
        data_file.open_file { |io| lines_in(io) }
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
