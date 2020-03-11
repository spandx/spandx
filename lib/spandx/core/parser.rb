# frozen_string_literal: true

module Spandx
  module Core
    class Parser
      UNKNOWN = Class.new do
        def self.parse(*_args)
          []
        end
      end

      attr_reader :catalogue

      def initialize(catalogue:)
        @catalogue = catalogue
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

        def for(path, catalogue: Spandx::Spdx::Catalogue.from_git)
          Spandx.logger.debug(path)
          result = ::Spandx::Core::Parser.find do |x|
            x.matches?(File.basename(path))
          end

          result&.new(catalogue: catalogue) || UNKNOWN
        end
      end
    end
  end
end
