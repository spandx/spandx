# frozen_string_literal: true

module Spandx
  module Dotnet
    # https://api.nuget.org/v3-flatcontainer/#{name}/#{version}/#{name}.nuspec
    # https://api.nuget.org/v3-flatcontainer/#{package.name}/index.json
    # https://docs.microsoft.com/en-us/nuget/api/package-base-address-resource
    class NugetGateway
      attr_reader :host

      def initialize(http: Spandx.http, catalogue:)
        @http = http
        @guess = Core::Guess.new(catalogue)
        @host = 'api.nuget.org'
      end

      def licenses_for(name, version)
        document = nuspec_for(name, version)

        extract_licenses_from(document) ||
          guess_licenses_from(document)
      end

      def each(page: Float::INFINITY)
        each_page(start_page: page) do |page_json|
          items_from(page_json).each do |item|
            yield(fetch_json(item['@id']), page_json['@id'])
          end
        end
      end

      private

      attr_reader :http, :guess

      def each_page(start_page:)
        url = "https://#{host}/v3/catalog0/index.json"
        items_from(fetch_json(url))
          .find_all { |page| page_number_from(page['@id']) <= start_page }
          .each { |page| yield fetch_json(page['@id']) }
      end

      def nuspec_url_for(name, version)
        "https://#{host}/v3-flatcontainer/#{name}/#{version}/#{name}.nuspec"
      end

      def nuspec_for(name, version)
        fetch_xml(nuspec_url_for(name, version))
      end

      def from_xml(xml)
        Nokogiri::XML(xml).tap(&:remove_namespaces!)
      end

      # TODO: Fix parsing https://github.com/NuGet/Home/wiki/Packaging-License-within-the-nupkg#license
      def extract_licenses_from(document)
        licenses = document.search('//package/metadata/license')
        licenses.map(&:text) if licenses.any?
      end

      def guess_licenses_from(document)
        document
          .search('//package/metadata/licenseUrl')
          .map { |node| guess_license_for(node.text) }
          .compact
      end

      def guess_license_for(url)
        response = http.get(url)

        guess.license_for(response.body) if http.ok?(response)
      end

      def fetch_json(url)
        response = http.get(url)
        http.ok?(response) ? JSON.parse(response.body) : {}
      end

      def fetch_xml(url)
        response = http.get(url)
        http.ok?(response) ? from_xml(response.body) : from_xml('<empty />')
      end

      def items_from(page)
        page['items']
          .sort_by { |x| x['commitTimeStamp'] }
          .reverse
      end

      def page_number_from(url)
        url.match(/page(?<page_number>\d+)\.json/)[:page_number].to_i
      end
    end
  end
end
