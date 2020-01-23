# frozen_string_literal: true

require 'tmpdir'
require 'xml-kit'
require 'licensee'

module Spandx
  module Parsers
    class PackagesConfig < Base
      def self.matches?(filename)
        filename.match?(/packages\.config/)
      end

      def parse(lockfile)
        Xml::Kit::Document.new(IO.read(lockfile))
          .find_all('//package')
          .map { |node| map_from(node) }
      end

      private

      def map_from(node)
        name = attribute_for('id', node)
        version = attribute_for('version', node)
        Dependency.new(
          name: name,
          version: version,
          licenses: nuget.licenses_for(name, version).map { |x| catalogue[x] }
        )
      end

      def attribute_for(key, node)
        node.attribute(key)&.value&.strip || node.at_xpath("./#{key}")&.content&.strip
      end

      def nuget
        @nuget ||= Gateways::Nuget.new
      end
    end
  end
end
