# frozen_string_literal: true

module Spandx
  module Core
    class Gateway
      class << self
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
        end

        def registry
          @registry ||= []
        end

        def for(dependency)
          find do |gateway|
            gateway.matches?(dependency)
          end
        end
      end
    end
  end
end
