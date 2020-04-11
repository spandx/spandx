# frozen_string_literal: true

module Spandx
  module Js
    class YarnPkg
      DEFAULT_SOURCE = 'https://registry.yarnpkg.com'
      attr_reader :http, :source

      def initialize(http: Spandx.http, source: DEFAULT_SOURCE)
        @http = http
        @source = source
      end

      def licenses_for(name, version)
        metadata = metadata_for(name, version)

        return [] if metadata.empty?

        [metadata['license']].compact
      end

      def metadata_for(name, version)
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
          uri.path = if package_name.include?('/')
                       '/' + package_name.sub('/', '%2f')
                     else
                       '/' + package_name + '/' + version
                     end
        end
      end
    end
  end
end
