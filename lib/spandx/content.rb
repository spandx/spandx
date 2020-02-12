# frozen_string_literal: true

module Spandx
  class Content
    attr_reader :raw

    def initialize(raw)
      @raw = raw
    end

    def tokens
      @tokens ||= tokenize(canonicalize(raw)).to_set
    end

    def similar?(other, algorithm: :dice_coefficient)
      case algorithm
      when :dice_coefficient
        similarity_score(other, algorithm: algorithm) > 89.0
      when :levenshtein
        similarity_score(other, algorithm: algorithm) < 3
      when :jaro_winkler
        similarity_score(other, algorithm: algorithm) > 89.0
      end
    end

    def similarity_score(other, algorithm: :dice_coefficient)
      case algorithm
      when :dice_coefficient
        dice_coefficient(other)
      when :levenshtein
        Text::Levenshtein.distance(raw, other.raw, 100)
      when :jaro_winkler
        JaroWinkler.distance(raw, other.raw) * 100.0
      end
    end

    private

    def canonicalize(content)
      content&.downcase
    end

    def tokenize(content)
      content.to_s.scan(/[a-zA-Z]+/)
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
