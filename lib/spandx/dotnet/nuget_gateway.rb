# frozen_string_literal: true

module Spandx
  module Dotnet
    # Bulk indexing reads the registration API, which returns a package's
    # *current* state -- every version with its license -- in one request:
    #   https://api.nuget.org/v3/registration5-gz-semver2/{id}/index.json
    # The catalog (catalog0) is an append-only event log with ~20M events for
    # ~450k packages, so it is used only to enumerate package ids, never as a
    # source of package state.
    #
    # Live single-package lookups still read the nuspec:
    #   https://api.nuget.org/v3-flatcontainer/{name}/{version}/{name}.nuspec
    # https://docs.microsoft.com/en-us/nuget/api/package-base-address-resource
    class NugetGateway < ::Spandx::Core::Gateway
      CATALOG_URL = 'https://api.nuget.org/v3/catalog0/index.json'
      REGISTRATION_URL = 'https://api.nuget.org/v3/registration5-gz-semver2'
      LICENSE_HOST = 'licenses.nuget.org'
      DEFAULT_CONCURRENCY = 25

      attr_reader :catalogue

      def initialize(http: Spandx.http, catalogue: ::Spandx::Spdx::Catalogue.empty, concurrency: DEFAULT_CONCURRENCY)
        @catalogue = catalogue
        @concurrency = concurrency
        super(http: http)
      end

      def licenses_for(dependency)
        extract_licenses_from(nuspec_for(dependency.name, dependency.version))
      end

      def matches?(dependency)
        dependency.package_manager == :nuget
      end

      # Yields every package id on nuget.org exactly once. The catalog is an
      # event log, so the same id recurs across pages; `Set#add?` is both the
      # dedup test and the insert, and runs only on the draining thread.
      def each(start_page: 0)
        seen = Set.new
        each_concurrently(page_urls(start_page: start_page), concurrency: @concurrency) { |url| ids_from(url) }
          .each { |id| yield(id) if seen.add?(id.downcase) }
      end

      def resolve(worker, id)
        worker.versions_for(id).map do |entry|
          [entry['id'] || id, entry['version'], licenses_from(entry)]
        end
      end

      # Every version of a package, from the registration index.
      def versions_for(id)
        fetch_json("#{REGISTRATION_URL}/#{id.downcase}/index.json")
          .fetch('items', [])
          .flat_map { |page| leaves_in(page) }
          .filter_map { |leaf| leaf['catalogEntry'] }
      end

      def licenses(name, version)
        extract_licenses_from(nuspec_for(name, version))
      end

      # Pure -- no network. An unrecognised url is reported verbatim: it is
      # what NuGet published, and `Guess` resolves it at scan time for the
      # handful of packages a scan actually touches.
      def licenses_from(entry)
        expression = entry['licenseExpression'].to_s
        return [expression] unless expression.empty?

        [license_from_url(entry['licenseUrl'])].compact
      end

      private

      def license_from_url(url)
        return if url.to_s.empty?

        expression_from(url) || catalogue.find_by_url(url)&.id || url
      end

      # licenses.nuget.org/<expression> encodes the SPDX expression in its
      # path, so it needs no lookup -- including composites like "(MIT OR X)".
      def expression_from(url)
        uri = URI.parse(url)
        return unless uri.host == LICENSE_HOST

        expression = CGI.unescape(uri.path.to_s.delete_prefix('/'))
        expression.empty? ? nil : expression
      rescue URI::InvalidURIError
        nil
      end

      # A registration page either inlines its leaves or points at a document
      # holding them (packages with more than ~128 versions).
      def leaves_in(page)
        page['items'] || fetch_json(page['@id']).fetch('items', [])
      end

      def page_urls(start_page:)
        items_from(fetch_json(CATALOG_URL))
          .map { |page| page['@id'] }
          .select { |url| page_number_from(url) >= start_page }
      end

      def ids_from(url)
        items_from(fetch_json(url)).filter_map { |item| item['nuget:id'] }
      end

      # The flat-container API is case-sensitive and only serves lowercase
      # ids/versions, even though NuGet package ids are nominally
      # case-insensitive (e.g. "Newtonsoft.Json" 404s, "newtonsoft.json" 200s).
      def nuspec_url_for(name, version)
        "https://api.nuget.org/v3-flatcontainer/#{name.downcase}/#{version.downcase}/#{name.downcase}.nuspec"
      end

      def nuspec_for(name, version)
        fetch_xml(nuspec_url_for(name, version))
      end

      def from_xml(xml)
        Nokogiri::XML(xml).tap(&:remove_namespaces!)
      end

      # TODO: Fix parsing https://github.com/NuGet/Home/wiki/Packaging-License-within-the-nupkg#license
      #
      # Resolves a licenseUrl the same way the bulk path does, rather than
      # downloading its body here -- `Guess` already fetches an unmapped url
      # once, and doing it here too meant fetching the same url twice.
      def extract_licenses_from(document)
        licenses = document.search('//package/metadata/license')
        return licenses.map(&:text) if licenses.any?

        document
          .search('//package/metadata/licenseUrl')
          .filter_map { |node| license_from_url(node.text) }
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
