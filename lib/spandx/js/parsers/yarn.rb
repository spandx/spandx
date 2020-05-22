# frozen_string_literal: true

module Spandx
  module Js
    module Parsers
      class Yarn < ::Spandx::Core::Parser
        def matches?(filename)
          filename.match?(/yarn\.lock$/)
        end

        def parse(file_path)
          YarnLock.new(file_path).each_with_object(Set.new) do |metadata, memo|
            memo << map_from(metadata)
          end
        end

        private

        def map_from(metadata)
          ::Spandx::Core::Dependency.new(
            package_manager: :yarn,
            name: metadata['name'],
            version: metadata['version'],
            meta: metadata
          )
        end
      end
    end
  end
end
