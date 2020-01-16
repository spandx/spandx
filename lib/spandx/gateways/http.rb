# frozen_string_literal: true

module Spandx
  module Gateways
    class Http
      attr_reader :http

      def initialize(http: Spandx.http)
        @http = http
      end

      def get(uri, default: nil)
        http.with_retry do |client|
          client.get(uri)
        end
      rescue *Net::Hippie::CONNECTION_ERRORS
        default
      end

      def ok?(response)
        response.is_a?(Net::HTTPSuccess)
      end
    end
  end
end
