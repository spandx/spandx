# frozen_string_literal: true

module Spandx
  module Ruby
    class Gateway < ::Spandx::Core::Gateway
      # https://guides.rubygems.org/rubygems-org-api-v2/
      def initialize(http: Spandx.http)
        @http = http
      end

      def licenses_for(dependency)
        details_on(dependency.name, dependency.version)['licenses'] || []
      end

      def matches?(dependency)
        dependency.package_manager == :rubygems
      end

      private

      attr_reader :http

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
