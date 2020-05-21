# frozen_string_literal: true

module Spandx
  module Core
    class LicensePlugin < Spandx::Core::Plugin
      def initialize(catalogue: Spdx::Catalogue.default)
        @guess = Guess.new(catalogue)
      end

      def enhance(dependency)
        return dependency unless known?(dependency.package_manager)
        return enhance_from_metadata(dependency) if available_in?(dependency.meta)

        licenses_for(dependency).each do |text|
          dependency.licenses << @guess.license_for(text)
        end
        dependency
      end

      private

      def licenses_for(dependency)
        results = cache_for(dependency).licenses_for(dependency.name, dependency.version)
        results && !results.empty? ? results : gateway_for(dependency).licenses_for(dependency)
      end

      def cache_for(dependency, git: Spandx.git)
        git = git[dependency.package_manager.to_sym] || git[:cache]
        key = key_for(dependency.package_manager)
        Spandx::Core::Cache.new(key, root: "#{git.root}/.index")
      end

      def known?(package_manager)
        %i[nuget maven rubygems npm yarn pypi composer].include?(package_manager)
      end

      def gateway_for(dependency)
        ::Spandx::Core::Gateway.find do |gateway|
          gateway.matches?(dependency)
        end
      end

      def available_in?(metadata)
        metadata.respond_to?(:[]) && metadata['license']
      end

      def enhance_from_metadata(dependency)
        dependency.meta['license'].each do |x|
          dependency.licenses << @guess.license_for(x)
        end
        dependency
      end

      def key_for(package_manager)
        package_manager == :yarn ? :npm : package_manager
      end
    end
  end
end
