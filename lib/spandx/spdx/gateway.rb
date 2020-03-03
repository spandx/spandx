# frozen_string_literal: true

module Spandx
  module Spdx
    class Gateway
      URL = 'https://spdx.org/licenses/licenses.json'

      def fetch(url: URL, http: Spandx.http, default: {})
        response = http.get(url, default: default)
        http.ok?(response) ? parse(response.body) : default
      end

      private

      def parse(json)
        JSON.parse(json, symbolize_names: true)
      end
    end
  end
end
