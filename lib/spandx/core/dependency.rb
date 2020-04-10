# frozen_string_literal: true

module Spandx
  module Core
    class Dependency
      attr_reader :name, :meta, :version, :licenses, :gateway

      def initialize(name:, version:, gateway:, meta: {})
        @name = name
        @version = version
        @licenses = gateway.licenses_for(name, version).compact
        @meta = meta
        @gateway = gateway
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
        [
          name,
          version,
          licenses.map(&:id)
        ]
      end

      def to_h
        {
          name: name,
          version: version,
          licenses: licenses.map(&:id)
        }
      end
    end
  end
end
