# frozen_string_literal: true

module Spandx
  module Core
    class LicensePlugin < Spandx::Core::Plugin
      def initialize(catalogue: Spdx::Catalogue.from_git)
        @guess = Core::Guess.new(catalogue)
      end

      def enhance(dependency)
        return dependency unless known?(dependency.package_manager)
        return enhance_from_metadata(dependency) if available_in?(dependency.meta)

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

      def known?(package_manager)
        %i[nuget maven rubygems npm yarn pypi composer].include?(package_manager)
      end

      def gateway_for(dependency)
        case dependency.package_manager
        when :nuget
          ::Spandx::Dotnet::NugetGateway.new
        when :maven
          ::Spandx::Java::Gateway.new
        when :rubygems
          ::Spandx::Ruby::Gateway.new
        when :yarn, :npm
          if dependency.meta['resolved']
            uri = URI.parse(dependency.meta['resolved'])
            Spandx::Js::YarnPkg.new(source: "#{uri.scheme}://#{uri.host}:#{uri.port}")
          else
            Spandx::Js::YarnPkg.new
          end
        when :pypi
          dependency.meta.empty? ? ::Spandx::Python::Pypi.new : ::Spandx::Python::Pypi.new(sources: ::Spandx::Python::Source.sources_from(dependency.meta))
        when :composer
          ::Spandx::Php::PackagistGateway.new
        end
      end

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
