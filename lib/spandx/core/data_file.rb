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
        return unless absolute_path.exist?

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

      def to_s
        absolute_path.to_s
      end

      private

      def to_csv(array)
        array.map { |value| one_line(value) }.to_csv(force_quotes: true)
      end

      # IndexFile addresses records by the byte offset of each line, so a value
      # containing a newline would split one record in two and misalign every
      # offset after it. Registries do publish such values -- a rubygems
      # license of "GPL 3 if you're compiling against Readline,\n" among them.
      # Valid CSV, but not something this format can hold.
      def one_line(value)
        value.to_s.gsub(/\s*\R\s*/, ' ').strip
      end
    end
  end
end
