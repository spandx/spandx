# frozen_string_literal: true

module Spandx
  module Python
    class LicensePlugin < Spandx::Core::Plugin
      def initialize(catalogue: Spdx::Catalogue.from_git)
        @guess = Core::Guess.new(catalogue)
      end

      def enhance(dependency)
        return dependency unless dependency.managed_by?(:pypi)

        gateway = ::Spandx::Core::CompositeGateway.new(
          ::Spandx::Core::Cache.for(dependency.package_manager),
          python_gateway(dependency)
        )
        gateway.licenses_for(dependency.name, dependency.version).each do |text|
          dependency.licenses << @guess.license_for(text)
        end
        dependency
      end

      private

      def python_gateway(dependency)
        dependency.meta.empty? ? ::Spandx::Python::Pypi.new : ::Spandx::Python::Pypi.new(sources: ::Spandx::Python::Source.sources_from(dependency.meta))
      end
    end
  end
end
