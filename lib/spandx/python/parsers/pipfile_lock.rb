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
          each_dependency(json) do |name, version|
            yield ::Spandx::Core::Dependency.new(
              package_manager: :pypi,
              name: name,
              version: version,
              meta: json
            )
          end
        end

        def each_dependency(json, groups: %w[default develop])
          groups.each do |group|
            json[group].each do |name, value|
              yield name, canonicalize(value['version'])
            end
          end
        end

        def canonicalize(version)
          version.gsub(/==/, '')
        end
      end
    end
  end
end
