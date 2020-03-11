# frozen_string_literal: true

module Spandx
  module Gateways
    class Http
      attr_reader :driver

      def initialize(driver: Http.default_driver, logger: Spandx.logger)
        @driver = driver
        @logger = logger
      end

      def get(uri, default: nil)
        driver.with_retry do |client|
          client.get(Addressable::URI.escape(uri))
        end
      rescue *Net::Hippie::CONNECTION_ERRORS
        default
      end

      def ok?(response)
        response.is_a?(Net::HTTPSuccess)
      end

      def self.default_driver
        @default_driver ||= Net::Hippie::Client.new.tap do |client|
          client.logger = @logger
          client.follow_redirects = 3
        end
      end
    end
  end
end
