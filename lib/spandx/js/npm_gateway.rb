# frozen_string_literal: true

module Spandx
  module Js
    # Bulk crawl of the npm registry, for index building. Deliberately not a
    # Core::Gateway subclass -- YarnPkg already owns live single-lookup
    # dispatch for :npm/:yarn during `spandx scan`, and Gateway subclasses
    # auto-register into that dispatch, which this has no business joining.
    class NpmGateway
      ALL_DOCS_URL = 'https://replicate.npmjs.com/registry/_all_docs'
      REGISTRY_URL = 'https://registry.npmjs.org'

      attr_reader :http

      def initialize(http: Spandx.http)
        @http = http
      end

      def each_name(batch_size: 1000)
        startkey = nil
        loop do
          rows = page(batch_size: batch_size, startkey: startkey)
          break if rows.empty?

          rows.each { |row| yield row['id'] }
          break if rows.size < batch_size

          startkey = rows.last['id']
        end
      end

      def metadata_for(name)
        response = http.get("#{REGISTRY_URL}/#{escaped(name)}", escape: false)
        return {} unless http.ok?(response)

        Oj.load(response.body)
      end

      private

      def escaped(name)
        name.include?('/') ? name.sub('/', '%2f') : name
      end

      def page(batch_size:, startkey:)
        url = "#{ALL_DOCS_URL}?limit=#{batch_size}"
        url += "&skip=1&startkey=#{CGI.escape(startkey.to_json)}" if startkey

        response = http.get(url, escape: false)
        return [] unless http.ok?(response)

        Oj.load(response.body).fetch('rows', [])
      end
    end
  end
end
