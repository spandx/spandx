# frozen_string_literal: true

module Spandx
  module Core
    class Parser
      UNKNOWN = Class.new do
        def self.parse(*_args)
          []
        end
      end

      def match?(_path)
        raise ::Spandx::Error, :match?
      end

      def parse(_dependency)
        raise ::Spandx::Error, :parse
      end

      class << self
        include Registerable

        def parse(path)
          self.for(path).parse(path)
        end

        def for(path)
          path = Pathname.new(path)
          return UNKNOWN if !path.exist? || path.zero?

          find { |x| x.match?(path) } || UNKNOWN
        end
      end
    end
  end
end
