# frozen_string_literal: true

module Spandx
  module Dotnet
    class LicensePlugin < Spandx::Core::Plugin
      def initialize(catalogue: Spdx::Catalogue.from_git)
        @guess = Core::Guess.new(catalogue)
        @cache = ::Spandx::Core::Cache.new(:nuget)
        @api = ::Spandx::Dotnet::NugetGateway.new
        @gateway = ::Spandx::Core::CompositeGateway.new(@cache, @api)
      end

      def enhance(dependency)
        return dependency unless dependency.managed_by?(:nuget)

        gateway.licenses_for(dependency.name, dependency.version).map do |text|
          dependency.licenses << @guess.license_for(text)
        end
        dependency
      end

      private

      attr_reader :gateway
    end
  end
end
