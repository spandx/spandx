module Spandx
  module Content
    # whitespace based tokenizer with configurable punctuation detection.
    class Tokenizer
      # Default whitespace separator.
      SEPARATOR = Regexp.new('[[:blank:]]+')

      # Characters only in the role of splittable prefixes.
      PREFIXES = ['¿', '¡']

      # Characters only in the role of splittable suffixes.
      SUFFIXES = ['!', '?', ',', ':', ';', '.']

      # Characters as splittable prefixes with an optional matching suffix.
      PAIR_PREFIXES = ['(', '{', '[', '<', '«', '„']

      # Characters as splittable suffixes with an optional matching prefix.
      PAIR_SUFFIXES = [')', '}', ']', '>', '»', '“']

      # Characters which can be both prefixes AND suffixes.
      BOTH = ['"', "'"]

      SPLITTABLES = PREFIXES + SUFFIXES + PAIR_PREFIXES + PAIR_SUFFIXES + BOTH
      PATTERN = Regexp.new("[^#{Regexp.escape(SPLITTABLES.join)}]+")

      def self.tokenize(content)
        return [] if content.nil? || content.chomp.strip == ''

        tokens = content
          .gsub(/\r/, ' ')
          .gsub(/\n/, ' ')
          .chomp
          .strip
          .split(SEPARATOR)
        return [] if tokens.empty?

        output = []
        tokens.each do |token|
          _prefix, stem, _suffix = token.partition(PATTERN)
          processed = stem.scan(/[a-zA-Z]/).join
          next if processed.empty?

          output << processed
        end
        output.flatten
      end
    end
  end
end
