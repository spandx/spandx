# frozen_string_literal: true

module Spandx
  module Php
    class PackagistGateway < ::Spandx::Core::Gateway
      LIST_URL = 'https://packagist.org/packages/list.json'

      def matches?(dependency)
        dependency.package_manager == :composer
      end

      def licenses_for(dependency)
        metadata_for(dependency.name)
          .find { |version| version['version'] == dependency.version }
          &.fetch('license', []) || []
      end

      def each
        response = http.get(LIST_URL)
        return unless http.ok?(response)

        Oj.load(response.body).fetch('packageNames', []).each { |name| yield name }
      end

      def metadata_for(name)
        response = http.get("https://repo.packagist.org/p2/#{name}.json")
        return [] unless http.ok?(response)

        unminify(Oj.load(response.body).dig('packages', name) || [])
      end

      def resolve(worker, name)
        worker.metadata_for(name).each { |version| yield(name, version['version'], Array(version['license'])) }
      end

      private

      # Packagist's v2 metadata omits `license` from a version entry when
      # it's unchanged from the entry before it in the array, to save
      # bandwidth. Fill it back in so every version carries its own license.
      def unminify(versions)
        last_license = nil
        versions.each do |version|
          if version.key?('license')
            last_license = version['license']
          else
            version['license'] = last_license
          end
        end
      end
    end
  end
end
