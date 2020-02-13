# frozen_string_literal: true

module Spandx
  module Gateways
    # https://guides.rubygems.org/rubygems-org-api-v2/
    class Rubygems
      def initialize(http: Spandx.http)
        @http = http
      end

      def licenses_for(name, version)
        found = index.licenses_for(name: name, version: version)
        found.any? ? found : details_on(name, version)['licenses'] || []
      end

      private

      attr_reader :http

      def index
        @index ||= Spandx::Rubygems::Index.new
      end

      def details_on(name, version)
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
