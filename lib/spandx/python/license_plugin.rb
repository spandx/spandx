# frozen_string_literal: true

module Spandx
  module Python
    class LicensePlugin < Spandx::Core::Plugin
      def initialize(catalogue: Spdx::Catalogue.from_git)
        @catalogue = catalogue
      end

      def enhance(dependency)
        return dependency unless dependency.managed_by?(:pypi)

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
          ::Spandx::Core::Cache.new(:pypi),
          python_gateway(dependency)
        )
      end

      def python_gateway(dependency)
        dependency.meta.empty? ? ::Spandx::Python::Pypi.new : ::Spandx::Python::Pypi.new(sources: ::Spandx::Python::Source.sources_from(meta))
      end
    end
  end
end
