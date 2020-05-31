# frozen_string_literal: true

module Spandx
  module Dotnet
    # https://api.nuget.org/v3-flatcontainer/#{name}/#{version}/#{name}.nuspec
    # https://api.nuget.org/v3-flatcontainer/#{package.name}/index.json
    # https://docs.microsoft.com/en-us/nuget/api/package-base-address-resource
    class NugetGateway < ::Spandx::Core::Gateway
      def initialize(http: Spandx.http)
        @http = http
      end

      def licenses_for(dependency)
        extract_licenses_from(nuspec_for(dependency.name, dependency.version))
      end

      def matches?(dependency)
        dependency.package_manager == :nuget
      end

      def each(start_page: 0)
        each_page(start_page: start_page) do |page_json|
          items_from(page_json).each do |item|
            yield(fetch_json(item['@id']), page_number_from(page_json['@id']))
          end
        end
      end

      private

      attr_reader :http

      def each_page(start_page:)
        url = 'https://api.nuget.org/v3/catalog0/index.json'
        items_from(fetch_json(url))
          .find_all { |page| page_number_from(page['@id']) >= start_page }
          .each { |page| yield fetch_json(page['@id']) }
      end

      def nuspec_url_for(name, version)
        "https://api.nuget.org/v3-flatcontainer/#{name}/#{version}/#{name}.nuspec"
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
        if licenses.any?
          licenses.map(&:text)
        else
          document
            .search('//package/metadata/licenseUrl')
            .map { |node| download_license(node.text) }
            .compact
        end
      end

      def download_license(url)
        response = http.get(url)
        http.ok?(response) ? response.body : url
      end

      def fetch_json(url)
        response = http.get(url)
        http.ok?(response) ? Oj.load(response.body) : {}
      end

      def fetch_xml(url)
        response = http.get(url)
        http.ok?(response) ? from_xml(response.body) : from_xml('<empty />')
      end

      def items_from(page)
        page.fetch('items', []).sort_by { |x| x['commitTimeStamp'] }
      end

      def page_number_from(url)
        url.match(/page(?<page_number>\d+)\.json/)[:page_number].to_i
      end
    end
  end
end
