# frozen_string_literal: true

module Spandx
  module Core
    class Circuit
      attr_reader :name, :state, :logger

      def initialize(name, state: :closed, logger: Spandx.logger)
        @name = name
        @state = state
        @logger = logger
      end

      def attempt
        return if open?

        open!
        result = yield
        close!
        result
      ensure
        logger.debug("#{name} #{state}")
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
