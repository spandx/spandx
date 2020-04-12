# frozen_string_literal: true

module Spandx
  module Dotnet
    class LicensePlugin < Spandx::Core::Plugin
      def initialize(catalogue: Spdx::Catalogue.from_git, package_manager: :nuget)
        @guess = Core::Guess.new(catalogue)
        @gateway = ::Spandx::Core::CompositeGateway.new(
          ::Spandx::Core::Cache.new(package_manager),
          ::Spandx::Dotnet::NugetGateway.new
        )
      end

      def enhance(dependency)
        return dependency unless dependency.managed_by?(:nuget)

        @gateway.licenses_for(dependency.name, dependency.version).map do |text|
          dependency.licenses << @guess.license_for(text)
        end
        dependency
      end
    end
  end
end
