# frozen_string_literal: true

module Spandx
  module Content
    class Text
      attr_reader :tokens

      def initialize(content, catalogue)
        @content = content
        @stripper = Stripper.new(catalogue)
        @tokens = tokenize(content)
      end

      # https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Dice%27s_coefficient#Ruby
      def similar?(other)
        overlap = (tokens & other.tokens).size
        total = tokens.size + other.tokens.size
        100.0 * (overlap * 2.0 / total)
      end

      private

      attr_reader :content, :stripper

      def tokenize(content)
        content = canonicalize(content)
        content = stripper.strip(content)
        content.downcase.scan(/(?:\w(?:'s|(?<=s)')?)+/).to_set
      end

      def canonicalize(content)
        NORMALIZATIONS.each do |key, hash|
          content = content.gsub(hash[:from], hash[:to])
        end
        content
          .gsub(/\b#{Regexp.union(WORDS.keys)}\b/, WORDS)
          .gsub(REGEXES[:bullet], "\n\n* ")
          .gsub(/\)\s+\(/, ')(')
      end

    end
  end
end
