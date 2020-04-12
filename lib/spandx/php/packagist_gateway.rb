# frozen_string_literal: true

module Spandx
  module Php
    class PackagistGateway
      attr_reader :http, :source

      def initialize(http: Spandx.http, source: 'https://repo.packagist.org')
        @source = source
        @http = http
      end

      def licenses_for(name, version)
        response = http.get("#{source}/p/#{name}.json")
        return [] unless http.ok?(response)

        json = JSON.parse(response.body)
        json['packages'][name][version]['license']
      end
    end
  end
end