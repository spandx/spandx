# frozen_string_literal: true

module Spandx
  module Parsers
    class GemfileLock
      def parse(lockfile)
        report = { version: '1.0', packages: [] }
        parser = ::Bundler::LockfileParser.new(IO.read(lockfile))
        parser.dependencies.each do |key, dependency|
          spec = dependency.to_spec
          report[:packages].push(name: key, version: spec.version.to_s, spdx: spec.license)
        end
        report
      end
    end
  end
end
