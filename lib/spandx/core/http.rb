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

      OPEN_TIMEOUT = 1
      READ_TIMEOUT = 5
      WRITE_TIMEOUT = 2
      KEEP_ALIVE_TIMEOUT = 30
      FOLLOW_REDIRECTS = 3

      attr_reader :retries

      def initialize(retries: 3)
        @retries = retries
        @connections = {}
      end

      def get(uri, default: nil, escape: true)
        return default if Spandx.airgap?

        with_retry { request(escape ? Addressable::URI.escape(uri) : uri, FOLLOW_REDIRECTS) }
      rescue *CONNECTION_ERRORS, URI::InvalidURIError
        default
      end

      def ok?(response)
        response.is_a?(Net::HTTPSuccess)
      end

      def close
        @connections.each_value { |http| http.finish if http.started? }
        @connections.clear
      end

      def self.thread_local
        Thread.current[:spandx_http] ||= new
      end

      def self.close_thread_local
        Thread.current[:spandx_http]&.close
        Thread.current[:spandx_http] = nil
      end

      private

      def request(uri, redirects)
        uri = URI.parse(uri.to_s)
        response = get_from(connection_for(uri), uri)
        return response unless redirects.positive? && response.is_a?(Net::HTTPRedirection)

        request(redirect_url_for(uri, response), redirects - 1)
      end

      def get_from(http, uri)
        http.start unless http.started?
        http.request(Net::HTTP::Get.new(uri))
      rescue StandardError
        http.finish if http.started?
        raise
      end

      def redirect_url_for(uri, response)
        location = response['location']
        location.start_with?('http') ? location : "#{uri.scheme}://#{uri.host}#{location}"
      end

      def connection_for(uri)
        @connections[[uri.scheme, uri.host, uri.port]] ||= build_connection(uri)
      end

      def build_connection(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT
        http.write_timeout = WRITE_TIMEOUT
        http.keep_alive_timeout = KEEP_ALIVE_TIMEOUT
        http
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
