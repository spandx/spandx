# frozen_string_literal: true

module Spandx
  module Parsers
    class GemfileLock < Base
      STRIP_BUNDLED_WITH = /^BUNDLED WITH$(\r?\n)   (?<major>\d+)\.\d+\.\d+/m.freeze

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
            licenses: licenses_for(specification)
          )
        end
      end

      private

      def dependencies_from(content)
        ::Bundler::LockfileParser
          .new(content.sub(STRIP_BUNDLED_WITH, ''))
          .specs
      end

      def licenses_for(specification)
        rubygems
          .licenses_for(specification.name, specification.version.to_s)
          .map { |x| catalogue[x] }
      end

      def rubygems
        @rubygems ||= Spandx::Rubygems::Gateway.new
      end
    end
  end
end
