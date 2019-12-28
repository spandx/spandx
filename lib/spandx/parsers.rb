# frozen_string_literal: true

module Spandx
  module Parsers
    class << self
      def register(parser)
        registry.add(parser)
      end

      def for(path)
        result = registry.find do |x|
          x.matches?(File.basename(path))
        end
        result&.new
      end

      def registry
        @registry ||= Set.new
      end
    end
  end
end

require 'spandx/parsers/gemfile_lock'
