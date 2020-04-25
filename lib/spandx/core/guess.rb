# frozen_string_literal: true

module Spandx
  module Core
    class Guess
      attr_reader :catalogue

      def initialize(catalogue)
        @catalogue = catalogue
      end

      def license_for(raw, algorithm: :dice_coefficient)
        raw.is_a?(Hash) ? from_hash(raw, algorithm) : from_string(raw, algorithm)
      end

      private

      def from_hash(hash, algorithm)
        from_string(hash[:name], algorithm) ||
          from_url(hash[:url], algorithm) ||
          unknown(hash[:name] || hash[:url])
      end

      def from_string(raw, algorithm)
        content = Content.new(raw)

        catalogue[raw] ||
          match_name(content, algorithm) ||
          match_body(content, algorithm) ||
          unknown(raw)
      end

      def from_url(url, algorithm)
        return if url.nil? || url.empty?

        response = Spandx.http.get(url)
        return unless Spandx.http.ok?(response)

        license_for(response.body, algorithm: algorithm)
      end

      def match_name(content, algorithm)
        catalogue.find do |license|
          next if license.deprecated_license_id?

          Content.new(license.name).similar?(content, algorithm: algorithm)
        end
      end

      def match_body(content, algorithm)
        score = Score.new(nil, nil)
        threshold = threshold_for(algorithm)
        direction = algorithm == :levenshtein ? method(:min) : method(:max)

        catalogue.each do |license|
          direction.call(content, license, score, threshold, algorithm) unless license.deprecated_license_id?
        end
        score&.item
      end

      def unknown(text)
        ::Spandx::Spdx::License.unknown(text)
      end

      def threshold_for(algorithm)
        {
          dice_coefficient: 89.0,
          jaro_winkler: 80.0,
          levenshtein: 80.0,
        }[algorithm.to_sym]
      end

      def min(target, other, score, threshold, algorithm)
        percentage = target.similarity_score(other.content, algorithm: algorithm)
        return if percentage > threshold
        return if score.score > 0.0 && score.score < percentage

        score.update(percentage, other)
      end

      def max(target, other, score, threshold, algorithm)
        percentage = target.similarity_score(other.content, algorithm: algorithm)
        return if percentage < threshold
        return if score.score >= percentage

        score.update(percentage, other)
      end
    end
  end
end
