# frozen_string_literal: true

module Spandx
  module Parsers
    class PipfileLock < Base
      def self.matches?(filename)
        filename.match?(/Pipfile.*\.lock/)
      end

      def parse(lockfile)
        report = { version: '1.0', packages: [] }
        dependencies_from(lockfile) do |dependency|
          report[:packages].push(dependency)
        end
        report
      end

      private

      def dependencies_from(lockfile)
        json = JSON.parse(IO.read(lockfile))
        each_dependency(json) do |name, version, definition|
          yield({ name: name, version: version, spdx: definition['license'] })
        end
      end

      def each_dependency(json, groups: %w[default develop])
        groups.each do |group|
          json[group].each do |name, value|
            version = value['version'].gsub(/==/, '')
            yield name, version, pypi_for(json).definition_for(name, version)
          end
        end
      end

      def pypi_for(json)
        Gateways::PyPI.new(
          sources: Gateways::PyPI::Source.sources_from(json)
        )
      end
    end
  end
end
