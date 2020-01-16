# frozen_string_literal: true

module Spandx
  module Gateways
    class Spdx
      URL = 'https://spdx.org/licenses/licenses.json'

      def fetch(url: URL)
        http = Http.new
        response = http.get(url, default: Catalogue.empty)

        if http.ok?(response)
          parse(response.body)
        else
          Catalogue.empty
        end
      end

      private

      def parse(json)
        build_catalogue(JSON.parse(json, symbolize_names: true))
      end

      def build_catalogue(hash)
        Catalogue.new(hash)
      end
    end
  end
end
