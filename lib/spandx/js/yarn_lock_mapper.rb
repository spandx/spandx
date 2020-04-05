# frozen_string_literal: true

module Spandx
  module Js
    class YarnLockMapper
      START_OF_DEPENDENCY_REGEX = %r{^"?(?<name>(@|\w|-|\.|/)+)@}i.freeze

      def map_from(io)
        header = io.readline
        return unless (matches = header.match(START_OF_DEPENDENCY_REGEX))

        metadata_from(matches[:name].gsub(/"/, ''), io)
      end

      private

      def metadata_from(name, io)
        YAML.safe_load(to_yaml(name, read_lines(io)))
      end

      def to_yaml(name, lines)
        (["name: \"#{name}\""] + lines)
          .map { |x| x.sub(/(?<=\w|")\s(?=\w|")/, ': ') }
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
