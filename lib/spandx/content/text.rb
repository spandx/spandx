# frozen_string_literal: true

module Spandx
  module Content
    class Text
      attr_reader :tokens

      def initialize(content)
        @content = content
        @tokens = tokenize(content)
      end

      def similar?(other)
        score = dice_coefficient(other)
        score > 89.0
      end

      # https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Dice%27s_coefficient#Ruby
      def dice_coefficient(other)
        overlap = (tokens & other.tokens).size
        total = tokens.size + other.tokens.size
        100.0 * (overlap * 2.0 / total)
      end

      private

      attr_reader :content

      def tokenize(content)
        return Set.new if empty?(content)

        canonicalize(content).scan(/(?:\w(?:'s|(?<=s)')?)+/).to_set
      end

      def canonicalize(content)
        content.downcase
      end

      def empty?(content)
        content.nil? || content.strip == ''
      end
    end
  end
end
