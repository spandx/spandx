# frozen_string_literal: true

module Spandx
  module Gateways
    class PyPI
      class Source
        attr_reader :name, :uri, :verify_ssl

        def initialize(source)
          @name = source['name']
          @uri = URI.parse(source['url'])
          @verify_ssl = source['verify_ssl']
        end

        def host
          @uri.host
        end

        def uri_for(name, version)
          URI.parse("https://#{host}/pypi/#{name}/#{version}/json")
        end

        def lookup(name, version)
          http = Http.new
          response = http.get(uri_for(name, version))
          response if http.ok?(response)
        end

        class << self
          def sources_from(json)
            meta = json['_meta']
            meta['sources'].map do |hash|
              Gateways::PyPI::Source.new(hash)
            end
          end

          def default
            new(
              'name' => 'pypi',
              'url' => 'https://pypi.org/simple',
              'verify_ssl' => true
            )
          end
        end
      end

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
