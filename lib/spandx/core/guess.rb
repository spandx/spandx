# frozen_string_literal: true

module Spandx
  module Core
    class Guess
      attr_reader :catalogue

      def initialize(catalogue)
        @catalogue = catalogue
        @name_search = FuzzyMatch.new(catalogue, read: :name)
      end

      def license_for(raw)
        raw.is_a?(Hash) ? from_hash(raw) : from_string(raw)
      end

      private

      def from_hash(hash)
        from_string(hash[:name]) ||
          from_url(hash[:url]) ||
          unknown(hash[:name] || hash[:url])
      end

      def from_string(raw)
        content = Content.new(raw)

        catalogue[raw] ||
          match_name(content) ||
          match_body(content) ||
          unknown(raw)
      end

      def from_url(url)
        return if url.nil? || url.empty?

        response = Spandx.http.get(url)
        return unless Spandx.http.ok?(response)

        license_for(response.body)
      end

      def match_name(content)
        return if content.tokens.size < 2 || content.tokens.size > 10

        @name_search.find(content.raw)
      end

      def match_body(content)
        score = Score.new(nil, nil)
        threshold = 89.0
        catalogue.each do |license|
          next if license.deprecated_license_id?

          max(content, license, score, threshold)
        end
        score&.item
      end

      def unknown(text)
        ::Spandx::Spdx::License.unknown(text)
      end

      def max(target, other, score, threshold)
        percentage = target.similarity_score(other.content)
        return if percentage < threshold
        return if score.score >= percentage

        score.update(percentage, other)
      end
    end
  end
end
