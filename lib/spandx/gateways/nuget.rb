# frozen_string_literal: true

module Spandx
  module Gateways
    # https://api.nuget.org/v3-flatcontainer/#{name}/#{version}/#{name}.nuspec
    # https://api.nuget.org/v3-flatcontainer/#{package.name}/index.json
    # https://docs.microsoft.com/en-us/nuget/api/package-base-address-resource
    class Nuget
      attr_reader :host

      def initialize(http: Spandx.http, catalogue:)
        @http = http
        @catalogue = catalogue
        @guess = Guess.new(catalogue)
        @host = 'api.nuget.org'
      end

      def update!(index, limit: nil)
        counter = 0
        each do |spec|
          upsert_into!(index, spec)

          if limit
            counter += 1
            break if counter > limit
          end
        end
      end

      def licenses_for(name, version)
        document = nuspec_for(name, version)

        extract_licenses_from(document) ||
          guess_licenses_from(document)
      end

      private

      attr_reader :http, :catalogue, :guess

      def each
        each_page do |page|
          items_from(page).each do |item|
            yield fetch_json(item['@id'])
          end
        end
      end

      def each_page
        url = "https://#{host}/v3/catalog0/index.json"
        items_from(fetch_json(url)).each do |page|
          yield fetch_json(page['@id'])
        end
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

      def upsert_into!(index, spec)
        key = [host, spec['id'], spec['version']]
        return if index.indexed?(key)

        if (license = spec['licenseExpression'])
          index.write(key, license)
        end
      end
    end
  end
end
