# frozen_string_literal: true

module Spandx
  module Parsers
    class GemfileLock < Base
      def self.matches?(filename)
        filename.match?(/Gemfile.*\.lock/) ||
          filename.match?(/gems.*\.lock/)
      end

      def parse(lockfile)
        dependencies_from(lockfile).map do |specification|
          Dependency.new(
            name: specification.name,
            version: specification.version.to_s,
            licenses: [catalogue[specification.license]]
          )
        end
      end

      private

      def dependencies_from(lockfile)
        ::Bundler::LockfileParser
          .new(IO.read(lockfile))
          .dependencies
          .map { |_key, dependency| dependency.to_spec }
      end
    end
  end
end
