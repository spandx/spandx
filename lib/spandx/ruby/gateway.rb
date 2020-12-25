# frozen_string_literal: true

module Spandx
  module Ruby
    class Gateway < ::Spandx::Core::Gateway
      # https://guides.rubygems.org/rubygems-org-api-v2/
      def initialize(http: Spandx.http)
        @http = http
      end

      def each
        response = http.get('https://index.rubygems.org/versions')
        return unless http.ok?(response)

        parse_each_from(StringIO.new(response.body)) do |item|
          yield item
        end
      end

      def licenses_for(dependency)
        details_on(dependency.name, dependency.version)['licenses'] || []
      end

      def matches?(dependency)
        dependency.package_manager == :rubygems
      end

      private

      attr_reader :http

      def parse_each_from(io)
        _created_at = io.readline
        _triple_dash = io.readline
        until io.eof?
          name, versions, _digest = io.readline.split(' ')
          versions.split(',').each do |version|
            yield({ name: name, version: version })
          end
        end
      end

      def details_on(name, version)
        url = "https://rubygems.org/api/v2/rubygems/#{name}/versions/#{version}.json"
        response = http.get(url, default: {})
        http.ok?(response) ? parse(response.body) : {}
      end

      def parse(json)
        Oj.load(json)
      end
    end
  end
end
