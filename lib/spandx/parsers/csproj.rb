# frozen_string_literal: true

module Spandx
  module Parsers
    class Csproj < Base
      def self.matches?(filename)
        filename.match?(/.*\.csproj/)
      end

      def parse(lockfile)
        document = from_xml(IO.read(lockfile))
        document.find_all('//PackageReference').map do |node|
          name = attribute_for('Include', node)
          version = attribute_for('Version', node)
          Dependency.new(
            name: name,
            version: version,
            licenses: nuget.licenses_for(name, version).map { |x| catalogue[x] }
          )
        end
      end

      private

      def from_xml(xml)
        Xml::Kit::Document.new(xml, namespaces: {})
      end

      def attribute_for(key, node)
        node.attribute(key)&.value&.strip ||
          node.at_xpath("./#{key}")&.content&.strip
      end

      def nuget
        @nuget ||= Gateways::Nuget.new
      end
    end
  end
end
