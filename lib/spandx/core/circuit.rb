# frozen_string_literal: true

module Spandx
  module Core
    class Circuit
      attr_reader :state

      def initialize(state: :closed)
        @state = state
      end

      def attempt
        return if open?

        open!
        result = yield
        close!
        result
      end

      def open!
        @state = :open
      end

      def close!
        @state = :closed
      end

      def open?
        state == :open
      end
    end
  end
end
