# frozen_string_literal: true

module Spandx
  module Content
    class Text
      attr_reader :tokens, :catalogue, :content

      def initialize(content, catalogue)
        @content = content
        @catalogue = catalogue
        @tokens = tokenize(content)
      end

      # https://en.wikibooks.org/wiki/Algorithm_Implementation/Strings/Dice%27s_coefficient#Ruby
      def similar?(other)
        overlap = (tokens & other.tokens).size
        total = tokens.size + other.tokens.size
        100.0 * (overlap * 2.0 / total)
      end

      private

      def tokenize(content)
        #content_normalized&.scan(/(?:\w(?:'s|(?<=s)')?)+/)&.to_set
        content = Stripper.new(catalogue).strip(content)
        content.downcase.scan(/(?:\w(?:'s|(?<=s)')?)+/).to_set
      end

      def _content
        @_content ||= content.to_s.dup.strip
      end

      def strip(regex_or_sym)
        return unless _content

        if regex_or_sym.is_a?(Symbol)
          meth = "strip_#{regex_or_sym}"
          return send(meth) if respond_to?(meth, true)

          unless REGEXES[regex_or_sym]
            raise ArgumentError, "#{regex_or_sym} is an invalid regex reference"
          end

          regex_or_sym = REGEXES[regex_or_sym]
        end

        @_content = _content.gsub(regex_or_sym, ' ').squeeze(' ').strip
      end

      def normalize(from_or_key, to = nil)
        operation = { from: from_or_key, to: to } if to
        operation ||= NORMALIZATIONS[from_or_key]

        if operation
          @_content = _content.gsub operation[:from], operation[:to]
        elsif respond_to?("normalize_#{from_or_key}", true)
          send("normalize_#{from_or_key}")
        else
          raise ArgumentError, "#{from_or_key} is an invalid normalization"
        end
      end

      def normalize_spelling
        normalize(/\b#{Regexp.union(VARIETAL_WORDS.keys)}\b/, VARIETAL_WORDS)
      end

      def normalize_bullets
        normalize(REGEXES[:bullet], "\n\n* ")
        normalize(/\)\s+\(/, ')(')
      end

    end
  end
end
