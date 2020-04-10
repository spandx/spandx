# frozen_string_literal: true

module Spandx
  module Core
    class Dependency
      attr_reader :package_manager, :name, :version, :meta

      def initialize(package_manager:, name:, version:, meta: {})
        @package_manager = package_manager
        @name = name
        @version = version
        @meta = meta
      end

      def licenses
        cache_for(package_manager).licenses_for(name, version)
      end

      def <=>(other)
        [name, version] <=> [other.name, other.version]
      end

      def hash
        [name, version].hash
      end

      def eql?(other)
        name == other.name && version == other.version
      end

      def to_a
        [name, version, licenses.map(&:id)]
      end

      def to_h
        { name: name, version: version, licenses: licenses.map(&:id) }
      end

      private

      def cache_for(package_manager)
        Spdx::Catalogue
          .from_git
          .proxy_for(gateway_for(package_manager))
      end

      def gateway_for(package_manager)
        case package_manager
        when :yarn, :npm
          if meta['resolved']
            uri = URI.parse(meta['resolved'])
            Spandx::Js::YarnPkg.new(source: "#{uri.scheme}://#{uri.host}:#{uri.port}")
          else
            Spandx::Js::YarnPkg.new
          end
        when :rubygems
          CompositeGateway.new(
            Cache.new(:rubygems, url: 'https://github.com/mokhan/spandx-rubygems.git'),
            ::Spandx::Ruby::Gateway.new
          )
        when :nuget
          CompositeGateway.new(
            Cache.new(:nuget, url: 'https://github.com/mokhan/spandx-index.git'),
            ::Spandx::Dotnet::NugetGateway.new
          )
        when :maven
          ::Spandx::Java::Gateway.new
        when :pypi
          if meta.empty?
            ::Spandx::Python::Pypi.new
          else
            ::Spandx::Python::Pypi.new(sources: ::Spandx::Python::Source.sources_from(meta))
          end
        end
      end
    end
  end
end
