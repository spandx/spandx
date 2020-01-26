# frozen_string_literal: true

module Spandx
  # https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Dice%27s_coefficient#Ruby
  class Content
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
end
