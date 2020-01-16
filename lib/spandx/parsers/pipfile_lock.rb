# frozen_string_literal: true

module Spandx
  module Parsers
    class PipfileLock < Base
      def self.matches?(filename)
        filename.match?(/Pipfile.*\.lock/)
      end

      def parse(lockfile)
        report = Report.new
        dependencies_from(lockfile) do |x|
          report.add(
            name: x[:name],
            version: x[:version],
            licenses: [x[:spdx]]
          )
        end
        report
      end

      private

      def dependencies_from(lockfile)
        json = JSON.parse(IO.read(lockfile))
        each_dependency(pypi_for(json), json) do |name, version, definition|
          yield({ name: name, version: version, spdx: definition['license'] })
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
        Gateways::PyPI.new(
          sources: Gateways::PyPI::Source.sources_from(json)
        )
      end
    end
  end
end
