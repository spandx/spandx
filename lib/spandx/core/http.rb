# frozen_string_literal: true

module Spandx
  module Core
    class Http
      attr_reader :driver

      def initialize(driver: Http.default_driver)
        @driver = driver
      end

      def get(uri, default: nil, escape: true)
        return default if Spandx.airgap?

        driver.with_retry do |client|
          client.get(escape ? Addressable::URI.escape(uri) : uri)
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
          client.follow_redirects = 3
        end
      end
    end
  end
end
