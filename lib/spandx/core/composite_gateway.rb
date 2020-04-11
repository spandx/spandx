# frozen_string_literal: true

module Spandx
  module Core
    class CompositeGateway
      attr_reader :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end

      def licenses_for(name, version)
        results = left.licenses_for(name, version)
        results && !results.empty? ? results : right.licenses_for(name, version)
      end
    end
  end
end
