# frozen_string_literal: true

module Spandx
  module Content
    class Text
      attr_reader :tokens, :threshold

      def initialize(content, threshold: 89.0)
        @threshold = threshold
        @tokens = tokenize(canonicalize(content))
      end

      def similar?(other)
        score = dice_coefficient(other)
        score > @threshold
      end

      # https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Dice%27s_coefficient#Ruby
      def dice_coefficient(other)
        overlap = (tokens & other.tokens).size
        total = tokens.size + other.tokens.size
        100.0 * (overlap * 2.0 / total)
      end

      private

      def tokenize(content)
        Tokenizer.tokenize(content).to_set
      end

      def canonicalize(content)
        content.downcase
      end
    end
  end
end
