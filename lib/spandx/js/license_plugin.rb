# frozen_string_literal: true

module Spandx
  module Js
    class LicensePlugin < Spandx::Core::Plugin
      def initialize(catalogue: Spdx::Catalogue.from_git)
        @catalogue = catalogue
      end

      def enhance(dependency)
        return dependency unless (dependency.managed_by?(:npm) || dependency.managed_by?(:yarn))

        licenses_for(dependency).each do |license|
          dependency.licenses << license
        end
        dependency
      end

      private

      attr_reader :catalogue

      def licenses_for(dependency)
        adapter = Spdx::GatewayAdapter.new(catalogue: catalogue, gateway: gateway(dependency))
        adapter.licenses_for(dependency.name, dependency.version)
      end

      def gateway(dependency)
        ::Spandx::Core::CompositeGateway.new(
          ::Spandx::Core::Cache.new(:nuget),
          js_gateway(dependency)
        )
      end

      def js_gateway(dependency)
        if dependency.meta['resolved']
          uri = URI.parse(meta['resolved'])
          return Spandx::Js::YarnPkg.new(source: "#{uri.scheme}://#{uri.host}:#{uri.port}")
        end

        Spandx::Js::YarnPkg.new
      end
    end
  end
end
