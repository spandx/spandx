# frozen_string_literal: true

module Spandx
  class Guess
    class Score
      attr_reader :score, :item

      def initialize(score, item)
        @score = score
        @item = item
      end

      def >(other)
        score > other.score
      end

      def <(other)
        score < other.score
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

    def license_for(content)
      this = Content::Text.new(content)

      max_score = catalogue.map do |license|
        next if license.deprecated_license_id?

        percentage = this.similarity_score(license.content)
        Score.new(percentage, license)
      end.compact.max

      max_score.item.id
    end
  end
end
