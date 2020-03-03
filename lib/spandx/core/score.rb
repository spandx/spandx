# frozen_string_literal: true

module Spandx
  module Core
    class Score
      include Comparable

      attr_reader :score, :item

      def initialize(score, item)
        update(score || 0.0, item)
      end

      def update(score, item)
        @score = score
        @item = item
      end

      def empty?
        score.nil? || item.nil?
      end

      def <=>(other)
        score <=> other.score
      end

      def to_s
        "#{score}: #{item}"
      end
    end
  end
end
