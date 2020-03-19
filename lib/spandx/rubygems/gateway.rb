# frozen_string_literal: true

module Spandx
  module Rubygems
    class Gateway
      # https://guides.rubygems.org/rubygems-org-api-v2/
      def initialize(http: Spandx.http)
        @http = http
      end

      def licenses_for(name, version)
        found = cache.licenses_for(name: name, version: version)
        found.any? ? found : details_on(name, version)['licenses'] || []
      end

      private

      attr_reader :http

      def cache
        @cache ||= Cache.new(:rubygems)
      end

      def details_on(name, version)
        Spandx.logger.debug("Cache miss: #{name}-#{version}")
        url = "https://rubygems.org/api/v2/rubygems/#{name}/versions/#{version}.json"
        response = http.get(url, default: {})
        http.ok?(response) ? parse(response.body) : {}
      end

      def parse(json)
        JSON.parse(json)
      end
    end
  end
end
