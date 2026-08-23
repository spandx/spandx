# frozen_string_literal: true

module Spandx
  module Spdx
    class Catalogue
      include Enumerable

      def initialize(catalogue = {})
        @catalogue = catalogue
      end

      def [](id)
        identity_map[id]
      end

      # Resolves a license URL without any network access, by two cheap
      # lookups: the last path segment being an SPDX id (`licenses.nuget.org/MIT`,
      # `opensource.org/license/apache-2.0`), then SPDX's own `seeAlso` URLs
      # (`www.apache.org/licenses/LICENSE-2.0`). Returns nil when neither hits.
      def find_by_url(url)
        return if url.nil? || url.to_s.empty?

        by_downcased_id[segment_from(url)] || by_url[normalize(url)]
      end

      def version
        catalogue[:licenseListVersion]
      end

      # Forces the lazy lookup tables. Call once before sharing an instance
      # across threads -- the memos are not guarded.
      def find_by_name(name)
        return if name.nil? || name.to_s.empty?

        by_name[name.to_s.downcase]
      end

      def warm!
        identity_map
        by_downcased_id
        by_name
        by_url
        self
      end

      def each
        licenses.each do |license|
          yield license
        end
      end

      class << self
        def latest(gateway: ::Spandx::Spdx::Gateway.new)
          new(gateway.fetch)
        end

        def from_json(json)
          new(JSON.parse(json, symbolize_names: true))
        end

        def from_file(path)
          from_json(Pathname.new(path).read)
        end

        def from_git
          json = Spandx.git[:spdx].read('json/licenses.json')
          json ? from_json(json) : latest
        end

        def default
          from_git
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

      def present?(item)
        item && !item.empty?
      end

      def identity_map
        @identity_map ||=
          catalogue.fetch(:licenses, []).each_with_object({}) do |hash, memo|
            license = License.new(hash)
            memo[license.id] = license if present?(license.id)
          end
      end

      def by_downcased_id
        @by_downcased_id ||= identity_map.transform_keys(&:downcase)
      end

      # PyPI's trove classifiers name a license rather than identify it:
      # "License :: OSI Approved :: MIT License" carries the SPDX *name*.
      def by_name
        @by_name ||= identity_map.each_value.with_object({}) do |license, memo|
          key = license.name.to_s.downcase
          memo[key] = license unless key.empty? || memo.key?(key)
        end
      end

      def by_url
        @by_url ||= identity_map.each_value.with_object({}) do |license, memo|
          Array(license.see_also).each do |url|
            key = normalize(url)
            memo[key] = license if present?(key) && !memo.key?(key)
          end
        end
      end

      def segment_from(url)
        url.to_s.split('/').last.to_s.sub(/\?.*\z/, '').sub(/\.(html?|php|txt)\z/i, '').downcase
      end

      def normalize(url)
        url.to_s.downcase
          .sub(%r{\Ahttps?://}, '')
          .sub(/\Awww\./, '')
          .sub(%r{/+\z}, '')
          .sub(/\.(html?|php|txt)\z/, '')
      end
    end
  end
end
