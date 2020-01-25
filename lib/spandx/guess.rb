# frozen_string_literal: true

module Spandx
  class Guess
    # https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Dice%27s_coefficient#Ruby
    class Dice
      attr_reader :bigrams

      def initialize(a)
        @bigrams = to_bigrams(a)
      end

      def similar?(other)
        overlap = (bigrams & other.bigrams).size
        total = bigrams.size + other.bigrams.size
        overlap * 2.0 / total
      end

      private

      def to_bigrams(x)
        x.each_char.each_cons(2).to_a
      end
    end

    class Score
      attr_reader :score, :item

      def initialize(score, item)
        @score = score
        @item = item
      end

      def <=>(other)
        self.score <=> other.score
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
      this = Dice.new(content)
      catalogue
        .map { |x| Score.new(this.similar?(Dice.new(x.details.text)), x) }
        .max
        .item
        .id
    end
  end
end
