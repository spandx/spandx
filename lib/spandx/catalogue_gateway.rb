# frozen_string_literal: true

module Spandx
  class CatalogueGateway
    URL = 'https://spdx.org/licenses/licenses.json'

    def initialize(http: default_client)
      @http = http
    end

    def fetch(url: URL)
      response = http.get(url)

      if response.code == '200'
        parse(response.body)
      else
        empty_catalogue
      end
    rescue *::Net::Hippie::CONNECTION_ERRORS
      empty_catalogue
    end

    private

    attr_reader :http

    def parse(json)
      build_catalogue(JSON.parse(json, symbolize_names: true))
    end

    def empty_catalogue
      build_catalogue(licenses: [])
    end

    def build_catalogue(hash)
      Catalogue.new(hash)
    end

    def default_client
      Net::Hippie::Client.new
    end
  end
end
