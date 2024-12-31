# frozen_string_literal: true

module Spandx
  module Core
    module Registerable
      include Enumerable

      def all
        @all ||= registry.map(&:new)
      end

      def each(&block)
        all.each do |x|
          block.call(x)
        end
      end

      def inherited(subclass)
        registry.push(subclass)
        super
      end

      def registry
        @registry ||= []
      end
    end
  end
end
