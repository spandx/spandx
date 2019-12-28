# frozen_string_literal: true

module Spandx
  module Parsers
    class Base
      class << self
        include Enumerable

        def each(&block)
          registry.each do |x|
            block.call(x)
          end
        end

        def inherited(subclass)
          registry.add(subclass)
        end

        def registry
          @registry ||= Set.new
        end
      end
    end
  end
end
