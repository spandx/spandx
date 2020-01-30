# frozen_string_literal: true

module Spandx
  class Index
    attr_reader :directory, :http

    def initialize(directory, http: Spandx.http)
      @directory = directory
      @http = http
    end

    def update!(gateway)
      gateway.each do |name, version, licenses|
        write(gateway.host, name, version, licenses)
      end
    end

    private

    def write(host, name, version, licenses)
      return if licenses.empty?

      open_data(key_for(host, name, version)) do |x|
        x.write(licenses.join(' '))
      end
    end

    def key_for(host, name, version)
      Digest::SHA1.hexdigest(File.join(host, name, version))
    end

    def open_data(key)
      data_dir = data_dir_for(key)
      data_file = File.join(data_dir, 'data')

      FileUtils.mkdir_p(data_dir)
      File.open(data_file, "w") do |file|
        yield file
      end
    end

    def data_dir_for(index_key)
      File.join(directory, *index_key.scan(/../))
    end
  end
end
