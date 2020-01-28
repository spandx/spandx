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

    class << self
      def latest(gateway: ::Spandx::Gateways::Spdx.new)
        gateway.fetch
      end

      def from_json(json)
        new(JSON.parse(json, symbolize_names: true))
      end

      def from_file(path)
        from_json(IO.read(path))
      end

      def from_git
        from_json(Spandx.db.read('json/licenses.json'))
      end

      def empty
        @empty ||= new(licenses: [])
      end
    end

    private

    attr_reader :catalogue

    def licenses
      @licenses ||= identity_map.values.sort
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
