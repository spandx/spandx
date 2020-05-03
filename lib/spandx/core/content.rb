# frozen_string_literal: true

module Spandx
  module Core
    class Content
      attr_reader :raw

      def initialize(raw)
        @raw = raw
      end

      def tokens
        @tokens ||= tokenize(canonicalize(raw)).to_set
      end

      def similar?(other)
        similarity_score(other) > 89.0
      end

      def similarity_score(other)
        dice_coefficient(other)
      end

      private

      def canonicalize(content)
        content&.downcase
      end

      def tokenize(content)
        content.to_s.scan(/[a-zA-Z\d.]+/)
      end

      def blank?(content)
        content.nil? || content.chomp.strip.empty?
      end

      # https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Dice%27s_coefficient#Ruby
      def dice_coefficient(other)
        overlap = (tokens & other.tokens).size
        total = tokens.size + other.tokens.size
        100.0 * (overlap * 2.0 / total)
      end
    end
  end
end
