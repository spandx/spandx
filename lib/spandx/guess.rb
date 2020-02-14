# frozen_string_literal: true

module Spandx
  class Guess
    class Score
      include Comparable

      attr_reader :score, :item

      def initialize(score, item)
        update(score || 0.0, item)
      end

      def update(score, item)
        @score = score
        @item = item
      end

      def empty?
        score.nil? || item.nil?
      end

      def <=>(other)
        score <=> other.score
      end

      def to_s
        "#{score}: #{item}"
      end
    end

    attr_reader :catalogue

    def initialize(catalogue)
      @catalogue = catalogue
    end

    def license_for(raw_content, algorithm: :dice_coefficient)
      content = Content.new(raw_content)
      score = Score.new(nil, nil)
      threshold = threshold_for(algorithm)
      direction = algorithm == :levenshtein ? method(:min) : method(:max)

      catalogue.each do |license|
        direction.call(content, license, score, threshold, algorithm) unless license.deprecated_license_id?
      end
      score&.item&.id
    end

    private

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
