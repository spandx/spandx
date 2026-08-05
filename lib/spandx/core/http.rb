# frozen_string_literal: true

module Spandx
  module Core
    # Holds one persistent connection per host; not safe to share across
    # threads. Concurrent callers should use `Http.thread_local` instead.
    class Http
      CONNECTION_ERRORS = [
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Errno::EHOSTUNREACH,
        Errno::EINVAL,
        IOError,
        Net::OpenTimeout,
        Net::ProtocolError,
        Net::ReadTimeout,
        OpenSSL::OpenSSLError,
        SocketError,
        Timeout::Error,
      ].freeze

      attr_reader :retries, :open_timeout, :read_timeout, :follow_redirects

      def initialize(retries: 3, open_timeout: 1, read_timeout: 5, follow_redirects: 3)
        @retries = retries
        @open_timeout = open_timeout
        @read_timeout = read_timeout
        @follow_redirects = follow_redirects
        @connections = {}
      end

      def get(uri, default: nil, escape: true)
        return default if Spandx.airgap?

        with_retry { request(escape ? Addressable::URI.escape(uri) : uri, follow_redirects) }
      rescue *CONNECTION_ERRORS, URI::InvalidURIError
        default
      end

      def ok?(response)
        response.is_a?(Net::HTTPSuccess)
      end

      def self.thread_local
        Thread.current[:spandx_http] ||= new
      end

      private

      def request(uri, redirects)
        uri = URI.parse(uri.to_s)
        response = connection_for(uri).get(uri)
        return response unless redirects.positive? && response.is_a?(Net::HTTPRedirection)

        request(redirect_url_for(uri, response), redirects - 1)
      end

      def redirect_url_for(uri, response)
        location = response['location']
        location.start_with?('http') ? location : "#{uri.scheme}://#{uri.host}#{location}"
      end

      def connection_for(uri)
        @connections[[uri.scheme, uri.host, uri.port]] ||= Connection.new(
          uri,
          open_timeout: open_timeout,
          read_timeout: read_timeout
        )
      end

      def with_retry
        0.upto(retries) do |attempt|
          return yield
        rescue *CONNECTION_ERRORS => error
          raise error if attempt == retries

          sleep(((2**attempt) * 0.1) + Random.rand(0.05))
        end
      end
    end
  end
end
