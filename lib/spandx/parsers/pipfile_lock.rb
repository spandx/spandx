# frozen_string_literal: true

module Spandx
  module Parsers
    class PipfileLock < Base
      def self.matches?(filename)
        filename.match?(/Pipfile.*\.lock/)
      end

      def parse(lockfile)
        report = { version: '1.0', packages: [] }
        dependencies_from(lockfile) do |dependency|
          report[:packages].push(dependency)
        end
        report
      end

      private

      def dependencies_from(lockfile)
        json = JSON.parse(IO.read(lockfile), symbolize_names: true)
        json[:default].each do |key, value|
          yield({
            name: key,
            version: value[:version],
            spdx: ''
          })
        end
      end
    end
  end
end
