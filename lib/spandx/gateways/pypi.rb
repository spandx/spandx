# frozen_string_literal: true

module Spandx
  module Gateways
    class PyPI < Gateway
      def definition_for(name, version)
        uri = "https://pypi.org/pypi/#{name}/#{version}/json"
        process(get(uri, default: {}))
      end

      class << self
        def definition(name, version)
          @pypi ||= new
          @pypi.definition_for(name, version)
        end
      end

      private

      def process(response)
        return JSON.parse(response.body).fetch('info', {}) if ok?(response)

        {}
      end
    end
  end
end
