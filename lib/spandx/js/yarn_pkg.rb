# frozen_string_literal: true

module Spandx
  module Js
    class YarnPkg < ::Spandx::Core::Gateway
      DEFAULT_SOURCE = 'https://registry.yarnpkg.com'
      attr_reader :http

      def initialize(http: Spandx.http)
        @http = http
      end

      def matches?(dependency)
        %i[npm yarn].include?(dependency.package_manager)
      end

      def licenses_for(dependency)
        metadata = metadata_for(dependency)

        return [] if metadata.empty?

        [metadata['license']].compact
      end

      def metadata_for(dependency)
        uri = uri_for(dependency)
        response = http.get(uri, escape: false)

        if http.ok?(response)
          json = Oj.load(response.body)
          json['versions'] ? json['versions'][dependency.version] : json
        else
          {}
        end
      end

      private

      def uri_for(dependency)
        URI.parse(source_for(dependency)).tap do |uri|
          uri.path = if dependency.name.include?('/')
                       '/' + dependency.name.sub('/', '%2f')
                     else
                       '/' + dependency.name + '/' + dependency.version
                     end
        end
      end

      def source_for(dependency)
        if dependency.meta['resolved']
          uri = URI.parse(dependency.meta['resolved'])
          "#{uri.scheme}://#{uri.host}:#{uri.port}"
        else
          DEFAULT_SOURCE
        end
      end
    end
  end
end
