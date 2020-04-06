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
        response = http.get(uri_for(source, name), escape: false)

        http.ok?(response) ? JSON.parse(response.body) : {}
      end

      private

      def uri_for(source, package_name)
        URI.parse(source).tap do |uri|
          uri.path = '/' + package_name.gsub('/', '%2f')
        end
      end
    end
  end
end
