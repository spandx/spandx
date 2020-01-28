# frozen_string_literal: true

module Spandx
  class Content
    attr_reader :tokens, :threshold

    def initialize(content, threshold: 89.0)
      @threshold = threshold
      @tokens = tokenize(canonicalize(content)).to_set
    end

    def similar?(other)
      similarity_score(other) > threshold
    end

    # https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Dice%27s_coefficient#Ruby
    def similarity_score(other)
      overlap = (tokens & other.tokens).size
      total = tokens.size + other.tokens.size
      100.0 * (overlap * 2.0 / total)
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
  end
end
