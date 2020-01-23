# frozen_string_literal: true

module Spandx
  module Gateways
    # https://api.nuget.org/v3-flatcontainer/#{name}/#{version}/#{name}.nuspec
    # https://api.nuget.org/v3-flatcontainer/#{package.name}/index.json
    # https://docs.microsoft.com/en-us/nuget/api/package-base-address-resource
    class Nuget
      def initialize(http: Spandx.http)
        @http = http
      end

      def licenses_for(name, version)
        document = nuspec_for(name, version)

        exact_licenses_from(document) ||
          guess_licenses_from(document)
      end

      private

      attr_reader :http

      def nuspec_url_for(name, version)
        "https://api.nuget.org/v3-flatcontainer/#{name}/#{version}/#{name}.nuspec"
      end

      def nuspec_for(name, version)
        from_xml(http.get(nuspec_url_for(name, version)).body)
      end

      def guess_license_in(content)
        Licensee::ProjectFiles::LicenseFile.new(content).license.key.upcase
      end

      def from_xml(xml)
        Nokogiri::XML(xml).tap(&:remove_namespaces!)
      end

      def exact_licenses_from(document)
        if (licenses = document.search('//package/metadata/license')).any?
          return licenses.map(&:text)
        end

        nil
      end

      def guess_licenses_from(document)
        document
          .search('//package/metadata/licenseUrl')
          .map { |node| guess_license_in(Spandx.http.get(node.text).body) }
      end
    end
  end
end
