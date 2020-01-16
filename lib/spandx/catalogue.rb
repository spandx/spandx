# frozen_string_literal: true

module Spandx
  class Catalogue
    include Enumerable

    def initialize(catalogue = {})
      @catalogue = catalogue
    end

    def [](id)
      identity_map[id]
    end

    def version
      catalogue[:licenseListVersion]
    end

    def each
      licenses.each do |license|
        yield license if present?(license.id)
      end
    end

    def self.latest
      CatalogueGateway.new.fetch
    end

    def self.from_file(path)
      new(JSON.parse(IO.read(path), symbolize_names: true))
    end

    private

    attr_reader :catalogue

    def licenses
      @licenses ||= identity_map.values
    end

    def map_from(license_hash)
      License.new(license_hash)
    end

    def present?(item)
      item && !item.empty?
    end

    def identity_map
      @identity_map ||=
        catalogue.fetch(:licenses, []).each_with_object({}) do |hash, memo|
          license = map_from(hash)
          memo[license.id] = license if present?(license.id)
        end
    end
  end
end
