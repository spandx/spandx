# frozen_string_literal: true

module Spandx
  module Js
    module Parsers
      class Yarn < ::Spandx::Core::Parser
        def self.matches?(filename)
          File.basename(filename) == 'yarn.lock'
        end

        def parse(file_path)
          YarnLock.new(file_path).each_with_object(Set.new) do |metadata, memo|
            memo << map_from(metadata)
          end
        end

        private

        def map_from(metadata)
          uri = URI.parse(metadata['resolved'])
          source = "#{uri.scheme}://#{uri.host}:#{uri.port}"

          ::Spandx::Core::Dependency.new(
            name: metadata['name'],
            version: metadata['version'],
            meta: metadata,
            gateway: catalogue.proxy_for(YarnPkg.new(source: source))
          )
        end
      end
    end
  end
end
