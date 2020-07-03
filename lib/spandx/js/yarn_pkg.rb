# frozen_string_literal: true

module Spandx
  module Js
    class YarnPkg < ::Spandx::Core::Gateway
      DEFAULT_SOURCE = 'https://registry.yarnpkg.com'
      attr_reader :http, :barrier, :semaphore

      def initialize(http: Async::HTTP::Internet.new)
        @http = http
        @barrier = Async::Barrier.new
        @semaphore = Async::Semaphore.new(100, parent: barrier)
      end

      def matches?(dependency)
        %i[npm yarn].include?(dependency.package_manager)
      end

      def licenses_for(dependency)
        metadata = metadata_for(dependency)&.wait

        return [] if metadata.nil? || metadata.empty?

        [metadata['license']].compact
      ensure
        barrier.wait
      end

      # rubocop:disable Metrics/AbcSize
      def metadata_for(dependency)
        semaphore.async do
          result = []
          response = http.get(uri_for(dependency).to_s)

          if response.status == 200
            json = Oj.load(response.read)

            result = json['versions'] ? json['versions'][dependency.version] : json
          end

          result
        rescue OpenSSL::SSL::SSLError => error
          Async.logger.error "Error #{error.inspect}"

          []
        ensure
          response&.finish
          http&.close
        end
      end
      # rubocop:enable Metrics/AbcSize

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
