# frozen_string_literal: true

module Spandx
  module Ruby
    module Parsers
      class GemfileLock < ::Spandx::Core::Parser
        STRIP_BUNDLED_WITH = /^BUNDLED WITH$\r?\n   \d+\.\d+\.\d+/m.freeze

        def match?(pathname)
          basename = pathname.basename
          basename.fnmatch?('Gemfile*.lock') ||
            basename.fnmatch?('gems*.lock')
        end

        def parse(lockfile)
          dependencies_from(lockfile).map do |specification|
            map_from(lockfile, specification)
          end
        end

        private

        def dependencies_from(filepath)
          content = filepath.read.sub(STRIP_BUNDLED_WITH, '')
          Dir.chdir(filepath.dirname) do
            ::Bundler::LockfileParser
              .new(content)
              .specs
          end
        end

        def map_from(lockfile, specification)
          ::Spandx::Core::Dependency.new(
            path: lockfile,
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
