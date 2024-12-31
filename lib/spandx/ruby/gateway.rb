# frozen_string_literal: true

module Spandx
  module Ruby
    # https://guides.rubygems.org/rubygems-org-api-v2/
    class Gateway < ::Spandx::Core::Gateway
      def each
        response = http.get('https://index.rubygems.org/versions')
        return unless http.ok?(response)

        parse_each_from(StringIO.new(response.body)) do |item|
          yield item
        end
      end

      def licenses_for(dependency)
        licenses(dependency.name, dependency.version)
      end

      def licenses(name, version)
        details_on(name, version)['licenses'] || []
      end

      def matches?(dependency)
        dependency.package_manager == :rubygems
      end

      private

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
