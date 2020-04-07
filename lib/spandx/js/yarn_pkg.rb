# frozen_string_literal: true

module Spandx
  module Js
    class YarnPkg
      DEFAULT_SOURCE = 'https://registry.yarnpkg.com'
      attr_reader :catalogue, :http

      def initialize(http: Spandx.http, catalogue:)
        @http = http
        @catalogue = catalogue
        @cache = {}
      end

      def licenses_for(name, version, source: DEFAULT_SOURCE)
        metadata = metadata_for(name, source: source)

        return [] if metadata.empty?
        return [] if metadata['versions'][version].nil?

        license_expression = metadata['versions'][version]['license']
        [catalogue[license_expression]].compact
      end

      def metadata_for(name, source: DEFAULT_SOURCE)
        uri = uri_for(source, name)
        with_cache(uri.to_s) do
          response = http.get(uri, escape: false)

          http.ok?(response) ? JSON.parse(response.body) : {}
        end
      end

      private

      def uri_for(source, package_name)
        URI.parse(source).tap do |uri|
          uri.path = '/' + package_name
        end
      end

      def with_cache(key)
        @cache.fetch(key) do
          @cache[key] = yield
        end
      end
    end
  end
end
