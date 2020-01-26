# frozen_string_literal: true

module Spandx
  class Guess
    class Score
      attr_reader :score, :item

      def initialize(score, item)
        @score = score
        @item = item
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
      this = Content::Text.new(content, catalogue)
      catalogue
        .map { |x| Score.new(this.similar?(x.content), x) }
        .max
        .item
        .id
    end
  end
end
