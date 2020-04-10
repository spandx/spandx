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
          text.is_a?(Hash) ? from_hash(text) : from_string(text)
        end
      end

      private

      def unknown(text)
        License.unknown(text)
      end

      def match_name(text)
        name = ::Spandx::Core::Content.new(text)

        catalogue.find do |license|
          score = name.similarity_score(::Spandx::Core::Content.new(license.name))
          score > 85
        end
      end

      def from_hash(hash)
        catalogue[hash[:name]] ||
          match_name(hash[:name]) ||
          (hash[:url] && @guess.license_for(Spandx.http.get(hash[:url]))) ||
          unknown(hash[:name] || hash[:url])
      end

      def from_string(text)
        catalogue[text] || @guess.license_for(text) || unknown(text)
      end
    end
  end
end
