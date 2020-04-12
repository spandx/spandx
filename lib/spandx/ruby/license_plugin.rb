# frozen_string_literal: true

module Spandx
  module Ruby
    class LicensePlugin < Spandx::Core::Plugin
      def initialize(catalogue: Spdx::Catalogue.from_git)
        @guess = Core::Guess.new(catalogue)
      end

      def enhance(dependency)
        return dependency unless dependency.managed_by?(:rubygems)

        gateway = ::Spandx::Core::CompositeGateway.new(
          ::Spandx::Core::Cache.for(dependency.package_manager),
          ::Spandx::Ruby::Gateway.new
        )
        gateway.licenses_for(dependency.name, dependency.version).each do |text|
          dependency.licenses << @guess.license_for(text)
        end
        dependency
      end
    end
  end
end
