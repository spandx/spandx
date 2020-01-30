# frozen_string_literal: true

module Spandx
  class Index
    attr_reader :directory, :http

    def initialize(directory, http: Spandx.http)
      @directory = directory
      @http = http
    end

    def update!
      json = fetch('https://api.nuget.org/v3/catalog0/index.json')
      json['items'].take(1).each do |item|
        json = fetch(item["@id"])
        json['items'].take(1).each do |other_item|
          build_index_for(fetch(other_item['@id']))
        end
      end
    end

    private

    def fetch(url)
      response = http.get(url)
      JSON.parse(response.body)
    end

    def build_index_for(package)
      sha1 = Digest::SHA1.hexdigest(File.join("api.nuget.org", package['id'], package['version']))
      path = File.join(directory, *sha1.scan(/../))
      FileUtils.mkdir_p(path)
    end
  end
end
