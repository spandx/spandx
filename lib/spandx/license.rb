# frozen_string_literal: true

module Spandx
  class License
    attr_reader :attributes

    def initialize(attributes = {})
      @attributes = attributes
    end

    def id
      attributes[:licenseId]
    end

    def name
      attributes[:name]
    end

    def reference
      attributes[:reference]
    end

    def deprecated_license_id?
      attributes[:isDeprecatedLicenseId]
    end

    def url
      attributes[:detailsUrl]
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
  end
end
