# frozen_string_literal: true

module Spandx
  module Js
    module Parsers
      class Npm < ::Spandx::Core::Parser
        def self.matches?(filename)
          File.basename(filename) == 'package-lock.json'
        end

        def parse(file_path)
          items = Set.new
          file_content = File.open(file_path).read
          package_lock = JSON.parse(file_content)
          package_lock['dependencies'].each do |dependency, metadata|
            uri = URI.parse(metadata['resolved'])
            source = "#{uri.scheme}://#{uri.host}"
            items.add(
              Spandx::Core::Dependency.new(
                name: dependency,
                version: metadata['version'],
                licenses: gateway.licenses_for(dependency, metadata['version'], source: source),
                meta: metadata
              )
            )
          end

          items
        end

        private

        def gateway
          # yarn and npm using same api end points
          @gateway ||= YarnPkg.new(catalogue: catalogue)
        end
      end
    end
  end
end
