# frozen_string_literal: true

module Spandx
  module Js
    module Parsers
      class Npm < ::Spandx::Core::Parser
        def match?(filename)
          File.basename(filename) == 'package-lock.json'
        end

        def parse(path)
          items = Set.new
          each_metadata(path) do |metadata|
            items.add(map_from(path, metadata))
          end
          items
        end

        private

        def each_metadata(path)
          package_lock = Oj.load(path.read)
          package_lock['dependencies'].each do |name, metadata|
            yield metadata.merge('name' => name)
          end
        end

        def map_from(path, metadata)
          Spandx::Core::Dependency.new(
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
