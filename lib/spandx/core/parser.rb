# frozen_string_literal: true

module Spandx
  module Core
    class Parser
      UNKNOWN = Class.new do
        def self.parse(*_args)
          []
        end
      end

      def matches?(_filename)
        raise ::Spandx::Error, :matches?
      end

      def parse(_dependency)
        raise ::Spandx::Error, :parse
      end

      class << self
        include Registerable

        def for(path)
          return UNKNOWN if File.size(path).zero?

          find { |x| x.matches?(File.basename(path)) } || UNKNOWN
        end
      end
    end
  end
end
