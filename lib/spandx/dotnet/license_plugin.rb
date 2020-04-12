# frozen_string_literal: true

module Spandx
  module Dotnet
    class LicensePlugin < Spandx::Core::Plugin
      GATEWAYS = {
        composer: ::Spandx::Php::PackagistGateway,
        maven: ::Spandx::Java::Gateway,
        nuget: ::Spandx::Dotnet::NugetGateway,
        rubygems: ::Spandx::Ruby::Gateway,
      }.freeze

      def initialize(catalogue: Spdx::Catalogue.from_git)
        @catalogue = catalogue
      end

      def enhance(dependency)
        return dependency unless dependency.managed_by?(:nuget)

        licenses_for(dependency).each do |license|
          dependency.licenses << license
        end
        dependency
      end

      private

      attr_reader :catalogue

      def licenses_for(dependency)
        Spdx::GatewayAdapter
          .new(catalogue: catalogue, gateway: combine(cache_for(dependency.package_manager), gateway_for(dependency.package_manager)))
          .licenses_for(dependency.name, dependency.version)
      end

      def combine(gateway, other_gateway)
        ::Spandx::Core::CompositeGateway.new(gateway, other_gateway)
      end

      def gateway_for(package_manager)
        case package_manager
        when :yarn, :npm
          js_gateway
        when :pypi
          python_gateway
        else
          GATEWAYS.fetch(package_manager, ::Spandx::Core::NullGateway).new
        end
      end

      def cache_for(package_manager)
        ::Spandx::Core::Cache.new(package_manager, url: package_manager == :rubygems ? 'https://github.com/mokhan/spandx-rubygems.git' : 'https://github.com/mokhan/spandx-index.git')
      end
    end
  end
end
