# frozen_string_literal: true

module Spandx
  module Core
    class Dependency
      attr_reader :package_manager, :name, :version, :licenses, :meta

      def initialize(package_manager:, name:, version:, licenses: [], meta: {})
        @package_manager = package_manager
        @name = name
        @version = version
        @meta = meta
        @licenses = []
      end

      def managed_by?(value)
        package_manager == value&.to_sym
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

      GATEWAYS = {
        rubygems: ::Spandx::Ruby::Gateway,
      }.freeze

      def xlicenses(catalogue: Spdx::Catalogue.from_git)
        Spdx::GatewayAdapter
          .new(catalogue: catalogue, gateway: combine(cache_for(package_manager), gateway_for(package_manager)))
          .licenses_for(name, version)
      end

      def gateway_for(package_manager)
          GATEWAYS.fetch(package_manager, NullGateway).new
      end

      def cache_for(package_manager)
        Cache.new(package_manager, url: package_manager == :rubygems ? 'https://github.com/mokhan/spandx-rubygems.git' : 'https://github.com/mokhan/spandx-index.git')
      end

      def combine(gateway, other_gateway)
        CompositeGateway.new(gateway, other_gateway)
      end
    end
  end
end
