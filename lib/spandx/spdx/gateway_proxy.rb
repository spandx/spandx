# frozen_string_literal: true

module Spandx
  module Spdx
    class GatewayProxy
      attr_reader :catalogue, :gateway

      def initialize(catalogue:, gateway:)
        @catalogue = catalogue
        @gateway = gateway
        @guess = Core::Guess.new(catalogue)
      end

      def licenses_for(name, version)
        gateway.licenses_for(name, version).map do |text|
          if text.is_a?(Hash)
            catalogue[text[:name]] || guess_name(text[:name]) || @guess.license_for(Spandx.http.get(text[:url]))
          else
            catalogue[text] || @guess.license_for(text) || unknown(text)
          end
        end
      end

      private

      def unknown(text)
        License.unknown(text)
      end

      def guess_name(text)
        name = ::Spandx::Core::Content.new(text)

        catalogue.find do |license|
          score = name.similarity_score(::Spandx::Core::Content.new(license.name))
          score > 85
        end
      end
    end
  end
end
