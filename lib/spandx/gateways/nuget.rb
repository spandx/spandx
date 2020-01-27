# frozen_string_literal: true

module Spandx
  module Gateways
    # https://api.nuget.org/v3-flatcontainer/#{name}/#{version}/#{name}.nuspec
    # https://api.nuget.org/v3-flatcontainer/#{package.name}/index.json
    # https://docs.microsoft.com/en-us/nuget/api/package-base-address-resource
    class Nuget
      def initialize(http: Spandx.http, catalogue:)
        @http = http
        @catalogue = catalogue
      end

      def licenses_for(name, version)
        document = nuspec_for(name, version)

        exact_licenses_from(document) ||
          guess_licenses_from(document)
      end

      private

      attr_reader :http, :catalogue

      def nuspec_url_for(name, version)
        "https://api.nuget.org/v3-flatcontainer/#{name}/#{version}/#{name}.nuspec"
      end

      def nuspec_for(name, version)
        from_xml(http.get(nuspec_url_for(name, version)).body)
      end

      def from_xml(xml)
        Nokogiri::XML(xml).tap(&:remove_namespaces!)
      end

      def exact_licenses_from(document)
        licenses = document.search('//package/metadata/license')
        licenses.map(&:text) if licenses.any?
      end

      def guess_licenses_from(document)
        guess = Guess.new(catalogue)
        document
          .search('//package/metadata/licenseUrl')
          .map { |node| guess.license_for(http.get(node.text).body) }
      end
    end
  end
end
