# frozen_string_literal: true

module Spandx
  module Core
    class Gateway
      def matches?(_dependency)
        raise ::Spandx::Error, :matches?
      end

      def licenses_for(_dependency)
        raise ::Spandx::Error, :licenses_for
      end

      class << self
        include Registerable
      end
    end
  end
end
