# frozen_string_literal: true

module Spandx
  module Dotnet
    class PackageReference
      attr_reader :name, :version

      def initialize(name:, version:)
        @name = name
        @version = version
      end

      def to_h
        {
          name: name,
          version: version
        }
      end
    end
  end
end
