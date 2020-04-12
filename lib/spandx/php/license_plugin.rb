# frozen_string_literal: true

module Spandx
  module Php
    class LicensePlugin < Spandx::Core::Plugin
      def initialize(catalogue: Spdx::Catalogue.from_git)
        @guess = Core::Guess.new(catalogue)
        @default_gateway = ::Spandx::Php::PackagistGateway.new
      end

      def enhance(dependency)
        return dependency unless dependency.managed_by?(:composer)
        return enhance_from_metadata(dependency) if available_in?(dependency.meta)

        gateway = ::Spandx::Core::CompositeGateway.new(
          ::Spandx::Core::Cache.for(dependency.package_manager),
          @default_gateway
        )
        gateway.licenses_for(dependency.name, dependency.version).each do |text|
          dependency.licenses << @guess.license_for(text)
        end
        dependency
      end

      private

      def available_in?(metadata)
        metadata['license']
      end

      def enhance_from_metadata(dependency)
        dependency.meta['license'].each do |x|
          dependency.licenses << @guess.license_for(x)
        end
        dependency
      end
    end
  end
end
