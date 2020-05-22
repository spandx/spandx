# frozen_string_literal: true

module Spandx
  module Js
    module Parsers
      class Yarn < ::Spandx::Core::Parser
        def match?(filename)
          filename.basename.fnmatch?('yarn.lock')
        end

        def parse(path)
          YarnLock.new(path).each_with_object(Set.new) do |metadata, memo|
            memo << map_from(path, metadata)
          end
        end

        private

        def map_from(path, metadata)
          ::Spandx::Core::Dependency.new(
            path: path,
            name: metadata['name'],
            version: metadata['version'],
            meta: metadata
          )
        end
      end
    end
  end
end
