# frozen_string_literal: true

module Spandx
  module Php
    class PackagistGateway < ::Spandx::Core::Gateway
      attr_reader :http, :source

      def initialize(http: Spandx.http, source: 'https://repo.packagist.org')
        @source = source
        @http = http
      end

      def matches?(dependency)
        dependency.package_manager == :composer
      end

      def licenses_for(dependency)
        response = http.get("#{source}/p/#{dependency.name}.json")
        return [] unless http.ok?(response)

        json = JSON.parse(response.body)
        json['packages'][dependency.name][dependency.version]['license']
      end
    end
  end
end
