# frozen_string_literal: true

module Spandx
  module Gateways
    class PyPI < Gateway
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

      def initialize(sources: [Source.default], http: nil)
        @sources = sources
        super(http: http)
      end

      def definition_for(name, version)
        source = @sources.first
        response = get(source.uri_for(name, version), default: {})
        if ok?(response)
          JSON.parse(response.body).fetch('info', {})
        else
          {}
        end
      end
    end
  end
end
