# frozen_string_literal: true

module Spandx
  module Parsers
    class PackagesConfig < Base
      def self.matches?(filename)
        filename.match?(/packages\.config/)
      end

      def parse(lockfile)
        document = REXML::Document.new(IO.read(lockfile))
        REXML::XPath.match(document, '//package').map do |package|
          attributes = package.attributes
          Dependency.new(
            name: attributes['id'],
            version: attributes['version'],
            licenses: []
          )
        end
      end
    end
  end
end
