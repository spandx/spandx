# frozen_string_literal: true

module Spandx
  module Core
    class Plugin
      def enhance(_dependency)
        raise ::Spandx::Error, :enhance
      end

      class << self
        include Registerable
      end
    end
  end
end
