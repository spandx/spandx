# frozen_string_literal: true

module Spandx
  module Js
    class LicensePlugin < Spandx::Core::Plugin
      def initialize(catalogue: Spdx::Catalogue.from_git)
        @guess = Core::Guess.new(catalogue)
        @default_gateway = Spandx::Js::YarnPkg.new
      end

      def enhance(dependency)
        return dependency unless dependency.managed_by?(:npm) || dependency.managed_by?(:yarn)

        gateway = ::Spandx::Core::CompositeGateway.new(
          ::Spandx::Core::Cache.for(dependency.package_manager),
          gateway_for(dependency)
        )
        gateway.licenses_for(dependency.name, dependency.version).each do |text|
          dependency.licenses << @guess.license_for(text)
        end
        dependency
      end

      private

      def gateway_for(dependency)
        if dependency.meta['resolved']
          uri = URI.parse(dependency.meta['resolved'])
          return Spandx::Js::YarnPkg.new(source: "#{uri.scheme}://#{uri.host}:#{uri.port}")
        end

        @default_gateway
      end
    end
  end
end
