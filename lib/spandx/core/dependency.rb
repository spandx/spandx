# frozen_string_literal: true

module Spandx
  module Core
    class Dependency
      attr_reader :name, :meta, :version, :licenses

      def initialize(name:, version:, licenses: [], meta: {})
        @name = name
        @version = version
        @licenses = licenses
        @meta = meta
      end

      def <=>(other)
        name <=> other.name
      end

      def to_a
        [
          name,
          version,
          licenses.compact.map(&:id)
        ]
      end

      def to_h
        {
          name: name,
          version: version,
          licenses: licenses.compact.map(&:id)
        }
      end
    end
  end
end
