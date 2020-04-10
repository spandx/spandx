# frozen_string_literal: true

module Spandx
  module Python
    module Parsers
      class PipfileLock < ::Spandx::Core::Parser
        def self.matches?(filename)
          filename.match?(/Pipfile.*\.lock/)
        end

        def parse(lockfile)
          results = []
          dependencies_from(lockfile) do |dependency|
            results << dependency
          end
          results
        end

        private

        def dependencies_from(lockfile)
          json = JSON.parse(IO.read(lockfile))
          pypi = pypi_for(json)
          each_dependency(pypi, json) do |name, version, definition|
            yield ::Spandx::Core::Dependency.new(
              name: name,
              version: version,
              meta: definition,
              gateway: catalogue.proxy_for(pypi)
            )
          end
        end

        def each_dependency(pypi, json, groups: %w[default develop])
          groups.each do |group|
            json[group].each do |name, value|
              version = canonicalize(value['version'])
              yield name, version, pypi.definition_for(name, version)
            end
          end
        end

        def canonicalize(version)
          version.gsub(/==/, '')
        end

        def pypi_for(json)
          Pypi.new(sources: Source.sources_from(json))
        end
      end
    end
  end
end
