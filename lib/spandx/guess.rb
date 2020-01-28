# frozen_string_literal: true

module Spandx
  class Guess
    class Score
      include Comparable

      attr_reader :score, :item

      def initialize(score, item)
        @score = score
        @item = item
      end

      def <=>(other)
        score <=> other.score
      end

      def to_s
        "#{score}: #{item}"
      end
    end

    attr_reader :catalogue

    def initialize(catalogue)
      @catalogue = catalogue
    end

    def license_for(raw_content)
      content = Content.new(raw_content)

      max_score = nil
      catalogue.each do |license|
        next if license.deprecated_license_id?

        percentage = content.similarity_score(license.content)
        if max_score.nil? || percentage > max_score.score
          max_score = Score.new(percentage, license)
        end
      end
      max_score.item.id
    end
  end
end
