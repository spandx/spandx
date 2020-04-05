# frozen_string_literal: true

module Spandx
  module Js
    module Parsers
      class Yarn < ::Spandx::Core::Parser
        def self.matches?(filename)
          File.basename(filename) == 'yarn.lock'
        end

        def parse(file_path)
          dependencies = []
          each_dependency_from(file_path) do |dependency|
            dependencies << dependency
          end
          dependencies
        end

        private

        def each_dependency_from(file_path)
          YarnLock.new(file_path).each do |metadata|
            yield ::Spandx::Core::Dependency.new(
              name: metadata['name'],
              version: metadata['version'],
              #licenses: gateway.licenses_for(metadata['name'], metadata['version']),
              meta: metadata
            )
          end
        end
      end
    end
  end
end
