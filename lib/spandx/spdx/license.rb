# frozen_string_literal: true

module Spandx
  module Spdx
    class License
      attr_reader :attributes

      def initialize(attributes = {})
        @attributes = attributes
      end

      def id
        attributes[:licenseId]
      end

      def id=(value)
        attributes[:licenseId] = value
      end

      def name
        attributes[:name]
      end

      def name=(value)
        attributes[:name] = value
      end

      def reference
        attributes[:reference]
      end

      def reference=(value)
        attributes[:reference] = value
      end

      def deprecated_license_id?
        attributes[:isDeprecatedLicenseId]
      end

      def url
        attributes[:detailsUrl]
      end

      def url=(value)
        attributes[:detailsUrl] = value
      end

      def osi_approved?
        attributes[:isOsiApproved]
      end

      def see_also
        attributes[:seeAlso]
      end

      def reference_number
        attributes[:referenceNumber]
      end

      def reference_number=(value)
        attributes[:referenceNumber] = value
      end

      def <=>(other)
        id <=> other.id
      end

      def to_s
        id
      end

      def inspect
        "#<Spandx::Spdx::License id='#{id}'>"
      end

      def self.unknown(text)
        new(licenseId: 'Nonstandard', name: text)
      end
    end
  end
end
