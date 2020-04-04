# frozen_string_literal: true

module Spandx
  module Python
    class Pypi
      def initialize(sources: [Source.default])
        @sources = sources
      end

      def definition_for(name, version)
        @sources.each do |source|
          response = source.lookup(name, version)
          return response.fetch('info', {}) unless response.empty?
        end
        {}
      end
    end
  end
end
