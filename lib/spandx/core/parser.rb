# frozen_string_literal: true

module Spandx
  module Core
    class Parser
      UNKNOWN = Class.new do
        def self.parse(*_args)
          []
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

        def for(path)
          Spandx.logger.debug(path)
          result = ::Spandx::Core::Parser.find do |x|
            x.matches?(File.basename(path))
          end

          result&.new || UNKNOWN
        end
      end
    end
  end
end
