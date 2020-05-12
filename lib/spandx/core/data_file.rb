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
        search_for("#{name}-#{version}")
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

      def search_for(term)
        min = 0
        max = index.size

        index.scan do |reader|
          until min >= max
            mid = (max - min) == 1 ? min : (((max - min) / 2) + min)
            line = reader.row(mid)
            return if line.nil?

            row = parse_row(line)
            comparison = (term <=> "#{row[0]}-#{row[1]}")
            return row if comparison.zero?

            if comparison.positive?
              min = mid + 1
            else
              max = mid
            end
          end
        end
      end

      def parse_row(line)
        CsvParser.parse(line) || CSV.parse(line)[0]
      end

      def to_csv(array)
        array.to_csv(force_quotes: true)
      end
    end
  end
end
