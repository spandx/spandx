# frozen_string_literal: true

module Spandx
  module Python
    class PyPI
      def initialize(sources: [Source.default])
        @sources = sources
      end

      def definition_for(name, version)
        @sources.each do |source|
          response = source.lookup(name, version)
          return JSON.parse(response.body).fetch('info', {}) if response
        end
        {}
      end
    end
  end
end
