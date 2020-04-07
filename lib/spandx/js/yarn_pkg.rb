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
        metadata = metadata_for(name, version, source: source)

        return [] if metadata.empty?
        [catalogue[metadata['license']]].compact
      end

      def metadata_for(name, version, source: DEFAULT_SOURCE)
        uri = uri_for(source, name, version)
        response = http.get(uri, escape: false)

        if http.ok?(response)
          json = JSON.parse(response.body)
          json['versions'] ? json['versions'][version] : json
        else
          {}
        end
      end

      private

      def uri_for(source, package_name, version)
        URI.parse(source).tap do |uri|
          if package_name.include?('/')
            uri.path = '/' + package_name.sub('/', '%2f')
          else
            uri.path = '/' + package_name + '/' + version
          end
        end
      end
    end
  end
end
