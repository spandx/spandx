# frozen_string_literal: true

module Spandx
  class Index
    attr_reader :directory, :http

    def initialize(directory, http: Spandx.http)
      @directory = directory
      @http = http
    end

    def update!(gateway, limit: nil)
      gateway.each(limit: limit) do |spec|
        name = spec['id']
        version = spec['version']
        key = key_for(gateway.host, name, version)
        next if indexed?(key)

        data = gateway.licenses_for(name, version).join(' ')
        write(key, data)
      end
    end

    private

    def write(key, data)
      return if data.nil? || data.empty?

      open_data(key) do |x|
        x.write(data)
      end
    end

    def key_for(host, name, version)
      Digest::SHA1.hexdigest(File.join(host, name, version))
    end

    def open_data(key)
      FileUtils.mkdir_p(data_dir_for(key))
      File.open(data_file_for(key), 'w') do |file|
        yield file
      end
    end

    def data_dir_for(index_key)
      File.join(directory, *index_key.scan(/../))
    end

    def data_file_for(key)
      File.join(data_dir_for(key), 'data')
    end

    def indexed?(key)
      File.exist?(data_file_for(key))
    end
  end
end
