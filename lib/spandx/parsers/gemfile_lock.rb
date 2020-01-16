# frozen_string_literal: true

module Spandx
  module Parsers
    class GemfileLock < Base
      def self.matches?(filename)
        filename.match?(/Gemfile.*\.lock/)
      end

      def parse(lockfile)
        report = Report.new
        dependencies_from(lockfile) do |dependency|
          spec = dependency.to_spec
          report.add(
            name: dependency.name,
            version: spec.version.to_s,
            licenses: [spec.license]
          )
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
    end
  end
end
