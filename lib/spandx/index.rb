# frozen_string_literal: true

module Spandx
  class Index
    attr_reader :directory, :http

    def initialize(directory, http: Spandx.http)
      @directory = directory
      @http = http
    end

    def update!(gateway)
      json = fetch('https://api.nuget.org/v3/catalog0/index.json')
      json['items'].take(1).each do |item|
        json = fetch(item['@id'])
        json['items'].each do |other_item|
          build_index_for(fetch(other_item['@id']), gateway)
        end
      end
    end

    private

    def fetch(url)
      response = http.get(url)
      JSON.parse(response.body)
    end

    def build_index_for(package, gateway)
      name = package['id']
      version = package['version']
      index_key = Digest::SHA1.hexdigest(File.join(gateway.host, name, version))
      data_dir = File.join(directory, *index_key.scan(/../))
      data_file = File.join(data_dir, 'data')

      FileUtils.mkdir_p(data_dir)
      licenses = gateway.licenses_for(name, version)
      puts "Writing #{licenses} to #{data_file}"
      IO.write(data_file, licenses.join(' '))
    end
  end
end
