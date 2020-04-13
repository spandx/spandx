# frozen_string_literal: true

module Spandx
  module Ruby
    module Parsers
      class GemfileLock < ::Spandx::Core::Parser
        STRIP_BUNDLED_WITH = /^BUNDLED WITH$(\r?\n)   (?<major>\d+)\.\d+\.\d+/m.freeze

        def self.matches?(filename)
          filename.match?(/Gemfile.*\.lock/) ||
            filename.match?(/gems.*\.lock/)
        end

        def parse(lockfile)
          dependencies_from(lockfile).map do |specification|
            map_from(specification)
          end
        end

        private

        def dependencies_from(filepath)
          content = IO.read(filepath)
          Dir.chdir(File.dirname(filepath)) do
            ::Bundler::LockfileParser
              .new(content.sub(STRIP_BUNDLED_WITH, ''))
              .specs
          end
        end

        def map_from(specification)
          ::Spandx::Core::Dependency.new(
            package_manager: :rubygems,
            name: specification.name,
            version: specification.version.to_s,
            meta: {
              dependencies: specification.dependencies,
              platform: specification.platform,
              source: specification.source
            }
          )
        end
      end
    end
  end
end
