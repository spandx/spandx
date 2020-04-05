# frozen_string_literal: true

module Spandx
  module Js
    class YarnLock
      START_OF_DEPENDENCY_REGEX = %r{^"?(?<name>(@|\w|-|\.|/)+)@}i.freeze
      INJECT_COLON = /(?<=\w|")\s(?=\w|")/
      attr_reader :file_path

      def initialize(file_path)
        @file_path = file_path
      end

      def each
        metadatum.each do |metadata|
          yield metadata
        end
      end

      private

      def metadatum
        @metadatum ||=
          begin
            items = Set.new
            File.open(file_path, 'r') do |io|
              until io.eof?
                metadata = map_from(io)
                next if metadata.nil? || metadata.empty?

                items << metadata
              end
            end
            items
          end
      end

      def map_from(io)
        header = io.readline
        return unless (matches = header.match(START_OF_DEPENDENCY_REGEX))

        metadata_from(matches[:name].gsub(/"/, ''), io)
      end

      def metadata_from(name, io)
        YAML.safe_load(to_yaml(name, read_lines(io)))
      end

      def to_yaml(name, lines)
        (["name: \"#{name}\""] + lines)
          .map { |x| x.sub(INJECT_COLON, ': ') }
          .join("\n")
      end

      def read_lines(io)
        [].tap do |lines|
          line = io.readline.strip
          until line.empty? || io.eof?
            lines << line
            line = io.readline.strip
          end
        end
      end
    end
  end
end
