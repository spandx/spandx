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

        Oj.load(response.body).dig('packages', name) || []
      end
    end
  end
end
