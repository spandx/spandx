# frozen_string_literal: true

module Spandx
  module Core
    class Http
      attr_reader :driver, :retries

      def initialize(driver: Http.default_driver, retries: 3)
        @driver = driver
        @retries = retries
        @circuits = Hash.new(true)
      end

      def get(uri, default: nil, escape: true)
        return default if Spandx.airgap?

        escaped_uri = escape ? Addressable::URI.escape(uri) : uri
        circuit_breaker_for(escaped_uri, default) do
          driver.with_retry(retries: retries) do |client|
            client.get(escaped_uri)
          end
        end
      rescue *Net::Hippie::CONNECTION_ERRORS
        default
      end

      def ok?(response)
        response.is_a?(Net::HTTPSuccess)
      end

      def self.default_driver
        @default_driver ||= Net::Hippie::Client.new.tap do |client|
          client.logger = Spandx.logger
          client.open_timeout = 1
          client.read_timeout = 5
          client.follow_redirects = 3
        end
      end

      private

      def circuit_breaker_for(uri, default)
        host = URI.parse(uri.to_s).host
        return default unless @circuits[host]

        @circuits[host] = false
        result = yield
        @circuits[host] = true
        result
      end
    end
  end
end
