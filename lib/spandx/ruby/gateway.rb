# frozen_string_literal: true

module Spandx
  module Ruby
    # https://guides.rubygems.org/rubygems-org-api-v2/
    class Gateway < ::Spandx::Core::Gateway
      VERSIONS_URL = 'https://index.rubygems.org/versions'
      VERSIONS_API = 'https://rubygems.org/api/v1/versions'
      VERSION_API = 'https://rubygems.org/api/v2/rubygems'

      # The compact index is an append log -- a gem reappears on a new line
      # every time it publishes -- so the same name recurs. `Set#add?` is both
      # the dedup test and the insert, and runs only on the draining thread.
      def each_package
        response = http.get(VERSIONS_URL)
        return unless http.ok?(response)

        seen = Set.new
        each_name_from(StringIO.new(response.body)) do |name|
          yield name if seen.add?(name)
        end
      end

      # One request returns every version of a gem with its licenses, rather
      # than one request per version.
      def resolve(worker, name)
        worker.versions_for(name).filter_map do |version|
          number = version['number']
          [name, number, Array(version['licenses'])] if number
        end
      end

      def versions_for(name)
        response = http.get("#{VERSIONS_API}/#{name}.json")
        return [] unless http.ok?(response)

        parsed = parse(response.body)
        parsed.is_a?(Array) ? parsed : []
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

      def each_name_from(io)
        io.readline # created_at
        io.readline # ---
        until io.eof?
          name = io.readline.split(' ').first
          yield name if name
        end
      end

      def details_on(name, version)
        url = "#{VERSION_API}/#{name}/versions/#{version}.json"
        response = http.get(url, default: {})
        http.ok?(response) ? parse(response.body) : {}
      end

      def parse(json)
        Oj.load(json)
      end
    end
  end
end
