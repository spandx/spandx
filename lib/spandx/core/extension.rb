# frozen_string_literal: true

module Spandx
  module Core
    class Extension
      UNKNOWN = Class.new do
        def self.enhance(x)
          x
        end
      end

      class << self
        include Enumerable

        def each(&block)
          registry.each do |x|
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
          result = ::Spandx::Core::Extension.find do |x|
            x.extends?(x)
          end

          result&.new || UNKNOWN
        end
      end
    end
  end
end
