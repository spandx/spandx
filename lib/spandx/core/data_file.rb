# frozen_string_literal: true

module Spandx
  module Core
    class DataFile
      include Enumerable

      attr_reader :absolute_path

      def initialize(absolute_path)
        @absolute_path = Pathname.new(absolute_path)
        FileUtils.mkdir_p(@absolute_path.dirname)
      end

      def each
        return unless exist?

        open_file(mode: 'rb') do |io|
          while (line = io.gets)
            yield CsvParser.parse(line)
          end
        end
      end

      def search(name:, version:)
        return if name.nil? || name.empty?
        return if version.nil? || name.empty?

        term = "#{name}-#{version}"
        index.search do |row|
          term <=> "#{row[0]}-#{row[1]}"
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
      rescue Errno::ENOENT => error
        Spandx.logger.error(error)
        nil
      end

      def index
        @index ||= IndexFile.new(self)
      end

      private

      def to_csv(array)
        array.to_csv(force_quotes: true)
      end
    end
  end
end
