# frozen_string_literal: true

module Spandx
  module Js
    class YarnLockMapper
      START_OF_DEPENDENCY_REGEX = %r{^"?(?<name>(@|\w|-|\.|/)+)@}i.freeze

      def map_from(io)
        header = io.readline
        return unless (matches = header.match(START_OF_DEPENDENCY_REGEX))

        metadata = metadata_from(matches, io)
        ::Spandx::Core::Dependency.new(
          name: metadata['name'],
          version: metadata['version'],
          licenses: [],
          meta: metadata
        )
      end

      private

      def metadata_from(matches, io)
        YAML.safe_load((["name: #{matches[:name].gsub(/"/, '')}"] + read_lines(io))
          .map { |x| x.sub(/(?<=\w|")\s(?=\w|")/, ": ") }
          .join("\n"))
      rescue => error
        Spandx.logger.error(error)
        {}
      end

      def read_lines(io)
        lines = []
        line = io.readline.strip
        until line.empty? || io.eof?
          lines << line
          line = io.readline.strip
        end
        lines
      end
    end
  end
end
