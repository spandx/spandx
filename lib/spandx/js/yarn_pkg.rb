# frozen_string_literal: true

module Spandx
  module Js
    class YarnPkg
      DEFAULT_SOURCE = 'https://registry.yarnpkg.com'
      attr_reader :catalogue, :http

      def initialize(http: Spandx.http, catalogue:)
        @http = http
        @catalogue = catalogue
      end

      def licenses_for(name, version, source: DEFAULT_SOURCE)
        metadata = metadata_for(name, source: source)

        return [] if metadata.empty?
        return [] if metadata['versions'][version].nil?

        license_expression = metadata['versions'][version]['license']
        [catalogue[license_expression]].compact
      end

      def metadata_for(name, source: DEFAULT_SOURCE)
        uri = uri_for(source)
        response = http.get("#{uri.scheme}://#{uri.host}/#{name}")

        http.ok?(response) ? JSON.parse(response.body) : {}
      end

      private

      def uri_for(source)
        URI.parse(source)
      end
    end
  end
end
