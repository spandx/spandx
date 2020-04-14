# frozen_string_literal: true

module Spandx
  module Core
    class Dependency
      attr_reader :package_manager, :name, :version, :licenses, :meta

      def initialize(package_manager:, name:, version:, licenses: [], meta: {})
        @package_manager = package_manager
        @name = name
        @version = version
        @licenses = licenses
        @meta = meta
      end

      def managed_by?(value)
        package_manager == value&.to_sym
      end

      def <=>(other)
        to_s <=> other.to_s
      end

      def hash
        to_s.hash
      end

      def eql?(other)
        to_s == other.to_s
      end

      def to_s
        @to_s ||= [name, version].compact.join(' ')
      end

      def inspect
        "#<Spandx::Core::Dependency name=#{name}, version=#{version}>"
      end

      def to_a
        [name, version, licenses.map(&:id)]
      end

      def to_h
        { name: name, version: version, licenses: licenses.map(&:id) }
      end
    end
  end
end
