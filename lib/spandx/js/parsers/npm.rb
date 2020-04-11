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
          each_metadata(file_path) do |metadata|
            items.add(map_from(metadata))
          end
          items
        end

        private

        def each_metadata(file_path)
          package_lock = JSON.parse(IO.read(file_path))
          package_lock['dependencies'].each do |name, metadata|
            yield metadata.merge('name' => name)
          end
        end

        def map_from(metadata)
          Spandx::Core::Dependency.new(
            package_manager: :npm,
            name: metadata['name'],
            version: metadata['version'],
            meta: metadata
          )
        end
      end
    end
  end
end
