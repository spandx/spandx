# frozen_string_literal: true

module Spandx
  module Parsers
    class GemfileLock < Base
      def self.matches?(filename)
        filename.match?(/Gemfile.*\.lock/) ||
          filename.match?(/gems.*\.lock/)
      end

      def parse(lockfile)
        ::Bundler::LockfileParser
          .new(IO.read(lockfile))
          .dependencies
          .map do |_key, dependency|
            spec = dependency.to_spec
            Dependency.new(
              name: dependency.name,
              version: spec.version.to_s,
              licenses: [catalogue[spec.license]]
            )
          end
      end
    end
  end
end
