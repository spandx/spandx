# frozen_string_literal: true

module Spandx
  class License
    class Details
      attr_reader :attributes

      def initialize(attributes = {})
        @attributes = attributes
      end

      def text
        attributes[:licenseText]
      end
    end

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

    def content
      @content ||= Content::Text.new(details.text)
    end

    def details
      path = File.expand_path(File.join(File.dirname(__FILE__), "../../spec/fixtures/spdx/json/details/#{id}.json"))
      Details.new(JSON.parse(IO.read(path), symbolize_names: true))
    end

    def <=>(other)
      id <=> other.id
    end

    def to_s
      id
    end
  end
end
