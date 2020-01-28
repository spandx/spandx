# frozen_string_literal: true

module Spandx
  module Content
    class Text
      # Default whitespace separator.
      SEPARATOR = Regexp.new('[[:blank:]]+')

      # Characters only in the role of splittable prefixes.
      PREFIXES = ['¿', '¡'].freeze

      # Characters only in the role of splittable suffixes.
      SUFFIXES = ['!', '?', ',', ':', ';', '.'].freeze

      # Characters as splittable prefixes with an optional matching suffix.
      PAIR_PREFIXES = ['(', '{', '[', '<', '«', '„'].freeze

      # Characters as splittable suffixes with an optional matching prefix.
      PAIR_SUFFIXES = [')', '}', ']', '>', '»', '“'].freeze

      # Characters which can be both prefixes AND suffixes.
      BOTH = ['"', "'"].freeze

      SPLITTABLES = PREFIXES + SUFFIXES + PAIR_PREFIXES + PAIR_SUFFIXES + BOTH
      PATTERN = Regexp.new("[^#{Regexp.escape(SPLITTABLES.join)}]+")

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
        return [] if blank?(content)

        output = []
        chop_up(content).each do |token|
          _prefix, stem, _suffix = token.partition(PATTERN)
          processed = stem.scan(/[a-zA-Z]/).join

          output.push(processed) unless processed.empty?
        end
        output
      end

      def chop_up(content)
        content
          .gsub(/\r/, ' ')
          .gsub(/\n/, ' ')
          .chomp
          .strip
          .split(SEPARATOR)
      end

      def blank?(content)
        content.nil? || content.chomp.strip.empty?
      end
    end
  end
end
