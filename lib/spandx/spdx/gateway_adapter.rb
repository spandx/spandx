# frozen_string_literal: true

module Spandx
  module Spdx
    class GatewayAdapter
      attr_reader :catalogue, :gateway

      def initialize(catalogue:, gateway:)
        @catalogue = catalogue
        @gateway = gateway
        @guess = Core::Guess.new(catalogue)
      end

      def licenses_for(name, version)
        gateway.licenses_for(name, version).map do |text|
          @guess.license_for(text)
        end
      end
    end
  end
end
