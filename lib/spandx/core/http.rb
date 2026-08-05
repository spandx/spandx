# frozen_string_literal: true

module Spandx
  module Core
    class Http
      attr_reader :driver, :retries

      def initialize(driver: Http.default_driver, retries: 3)
        @driver = driver
        @retries = retries
      end

      def get(uri, default: nil, escape: true)
        return default if Spandx.airgap?

        driver.with_retry(retries: retries) do |client|
          client.get(escape ? Addressable::URI.escape(uri) : uri)
        end
      rescue *Net::Hippie::CONNECTION_ERRORS, URI::InvalidURIError
        default
      end

      def ok?(response)
        response.is_a?(Net::HTTPSuccess)
      end

      def self.default_driver
        @default_driver ||= Net::Hippie::Client.new(
          follow_redirects: 3,
          logger: Spandx.logger,
          open_timeout: 1,
          read_timeout: 5
        )
      end
    end
  end
end
