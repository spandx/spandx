# frozen_string_literal: true

module Spandx
  class Guess
    class Score
      include Comparable

      attr_reader :score, :item

      def initialize(score, item)
        update(score, item)
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
      catalogue.each do |license|
        next if license.deprecated_license_id?

        case algorithm
        when :levenshtein
          min(content, license, score, 80, :levenshtein)
        when :dice_coefficient
          max(content, license, score, 89.0, :dice_coefficient)
        when :jaro_winkler
          max(content, license, score, 80.0, :jaro_winkler)
        end
      end
      score&.item&.id
    end

    private

    def min(target, other, score, threshold, algorithm)
      percentage = target.similarity_score(other.content, algorithm: algorithm)
      if (percentage < threshold) && (score.empty? || percentage < score.score)
        score.update(percentage, other)
      end
    end

    def max(target, other, score, threshold, algorithm)
      percentage = target.similarity_score(other.content, algorithm: algorithm)
      if (percentage > threshold) && (score.empty? || percentage > score.score)
        score.update(percentage, other)
      end
    end
  end
end
