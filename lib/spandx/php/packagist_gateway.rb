# frozen_string_literal: true

module Spandx
  module Php
    class PackagistGateway < ::Spandx::Core::Gateway
      attr_reader :http

      def initialize(http: Spandx.http)
        @http = http
      end

      def matches?(dependency)
        dependency.package_manager == :composer
      end

      def licenses_for(dependency)
        response = http.get("https://repo.packagist.org/p/#{dependency.name}.json")
        return [] unless http.ok?(response)

        json = JSON.parse(response.body)
        json['packages'][dependency.name][dependency.version]['license']
      end
    end
  end
end
