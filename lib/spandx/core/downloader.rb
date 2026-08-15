# frozen_string_literal: true

module Spandx
  module Core
    # Streams a response straight to disk. Bulk index files -- Maven's is over
    # 3GB -- can neither be buffered in memory nor finish inside the read
    # timeout that suits an API call, so this keeps its own connection rather
    # than borrowing one of `Http`'s pooled ones.
    class Downloader
      READ_TIMEOUT = 120

      def initialize(open_timeout: Http::OPEN_TIMEOUT, read_timeout: READ_TIMEOUT)
        @open_timeout = open_timeout
        @read_timeout = read_timeout
      end

      # Returns whether the file was written.
      def call(uri, path, redirects)
        raise URI::InvalidURIError, "not an HTTP(S) URI: #{uri}" unless uri.is_a?(URI::HTTP)

        connection_for(uri).start do |http|
          http.request(Net::HTTP::Get.new(uri)) do |response|
            return redirect(uri, path, response, redirects) if redirecting?(response, redirects)
            return false unless response.is_a?(Net::HTTPSuccess)

            return write(response, path)
          end
        end
      end

      private

      def redirecting?(response, redirects)
        redirects.positive? && response.is_a?(Net::HTTPRedirection)
      end

      def redirect(uri, path, response, redirects)
        location = response['location']
        location = "#{uri.scheme}://#{uri.host}#{location}" unless location.start_with?('http')
        call(URI.parse(location), path, redirects - 1)
      end

      def write(response, path)
        File.open(path, 'wb') do |io|
          response.read_body { |chunk| io.write(chunk) }
        end
        true
      end

      def connection_for(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = @open_timeout
        http.read_timeout = @read_timeout
        http
      end
    end
  end
end
