# frozen_string_literal: true

module Spandx
  module Parsers
    class GemfileLock < Base
      def self.matches?(filename)
        filename.match?(/Gemfile.*\.lock/)
      end

      def parse(lockfile)
        report = { version: '1.0', packages: [] }
        dependencies_from(lockfile) do |dependency|
          report[:packages].push(map_from(dependency))
        end
        report
      end

      private

      def dependencies_from(lockfile)
        ::Bundler::LockfileParser
          .new(IO.read(lockfile))
          .dependencies.each do |_key, dependency|
          yield dependency
        end
      end

      def map_from(dependency)
        spec = dependency.to_spec
        {
          name: dependency.name,
          version: spec.version.to_s,
          spdx: spec.license
        }
      end
    end
  end
end
