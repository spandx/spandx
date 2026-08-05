# frozen_string_literal: true

module Spandx
  module Core
    class Http
      # A single keep-alive connection to one host. Reused across many
      # `#get` calls to avoid paying a TCP/TLS handshake per request.
      class Connection
        def initialize(uri, open_timeout:, read_timeout:)
          @http = Net::HTTP.new(uri.host, uri.port)
          @http.use_ssl = uri.scheme == 'https'
          @http.open_timeout = open_timeout
          @http.read_timeout = read_timeout
        end

        def get(uri)
          @http.start unless @http.started?
          @http.request(Net::HTTP::Get.new(uri))
        rescue StandardError
          reset!
          raise
        end

        private

        def reset!
          @http.finish if @http.started?
        rescue IOError
          nil
        end
      end
    end
  end
end
