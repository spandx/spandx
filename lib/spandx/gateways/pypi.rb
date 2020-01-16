# frozen_string_literal: true

module Spandx
  module Gateways
    class PyPI
      def initialize(http = Spandx.http)
        @http = http
      end

      def definition_for(name, version)
        uri = "https://pypi.org/pypi/#{name}/#{version}/json"
        process(@http.with_retry { |client| client.get(uri) })
      rescue *Net::Hippie::CONNECTION_ERRORS
        {}
      end

      class << self
        def definition(name, version)
          @pypi ||= new
          @pypi.definition_for(name, version)
        end
      end

      private

      def process(response)
        return JSON.parse(response.body).fetch('info', {}) if ok?(response)

        {}
      end

      def ok?(response)
        response.is_a?(Net::HTTPSuccess)
      end
    end
  end
end
