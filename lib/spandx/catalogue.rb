# frozen_string_literal: true

module Spandx
  class Catalogue
    include Enumerable

    def initialize(catalogue = {})
      @catalogue = catalogue
    end

    def [](id)
      find do |license|
        license.id == id
      end
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
      @licenses ||= catalogue.fetch(:licenses, []).map { |x| map_from(x) }
    end

    def map_from(license_hash)
      License.new(license_hash)
    end

    def present?(item)
      item && !item.empty?
    end
  end
end
