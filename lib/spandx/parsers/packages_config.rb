# frozen_string_literal: true

require 'tmpdir'
require 'xml-kit'
require 'licensee'

# https://api.nuget.org/v3-flatcontainer/#{name}/#{version}/#{name}.nuspec
# https://api.nuget.org/v3-flatcontainer/#{package.name}/index.json
# https://docs.microsoft.com/en-us/nuget/api/package-base-address-resource
module Spandx
  module Parsers
    class PackagesConfig < Base
      NAMESPACES = {
        pkg: 'http://schemas.microsoft.com/packaging/2013/05/nuspec.xsd'
      }.freeze

      def self.matches?(filename)
        filename.match?(/packages\.config/)
      end

      def parse(lockfile)
        from_xml(IO.read(lockfile))
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
          licenses: licenses_for(name, version)
        )
      end

      def attribute_for(key, node)
        node.attribute(key)&.value&.strip || node.at_xpath("./#{key}")&.content&.strip
      end

      def licenses_for(name, version)
        from_xml(Spandx.http.get(nuspec_url_for(name, version)).body)
          .find_all('//pkg:package/pkg:metadata/pkg:licenseUrl')
          .map { |node| guess_license_in(Spandx.http.get(node.text).body) }
      end

      def from_xml(xml)
        Xml::Kit::Document.new(xml, namespaces: NAMESPACES)
      end

      def guess_license_in(content)
        catalogue[Licensee::ProjectFiles::LicenseFile.new(content).license.key.upcase]
      end

      def nuspec_url_for(name, version)
        "https://api.nuget.org/v3-flatcontainer/#{name}/#{version}/#{name}.nuspec"
      end
    end
  end
end
