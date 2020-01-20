# frozen_string_literal: true

module Spandx
  module Parsers
    class GemfileLock < Base
      def self.matches?(filename)
        filename.match?(/Gemfile.*\.lock/) ||
          filename.match?(/gems.*\.lock/)
      end

      def parse(lockfile)
        content = IO.read(lockfile)
        dependencies_from(content).map do |specification|
          Dependency.new(
            name: specification.name,
            version: specification.version.to_s,
            licenses: [catalogue[specification.license]]
          )
        end
      end

      private

      def dependencies_from(content)
        ::Bundler::LockfileParser.new(content)
          .dependencies
          .map { |_key, dependency| dependency.to_spec }
      end
    end
  end
end
