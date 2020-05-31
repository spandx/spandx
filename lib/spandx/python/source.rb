# frozen_string_literal: true

module Spandx
  module Python
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
        "https://#{host}/pypi/#{name}/#{version}/json"
      end

      def lookup(name, version, http: Spandx.http)
        response = http.get(uri_for(name, version))
        if http.ok?(response)
          Oj.load(response.body)
        else
          {}
        end
      end

      def ==(other)
        name == other.name &&
          uri.to_s == other.uri.to_s &&
          verify_ssl == other.verify_ssl
      end

      def eql(other)
        self == other
      end

      class << self
        def sources_from(json)
          meta = json['_meta']
          meta['sources'].map do |hash|
            new(hash)
          rescue URI::InvalidURIError
            default
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
  end
end
