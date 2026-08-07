# frozen_string_literal: true

module Spandx
  module Core
    class Gateway
      include ConcurrentEach

      attr_reader :http

      def initialize(http: Spandx.http)
        @http = http
      end

      def matches?(_dependency)
        raise ::Spandx::Error, :matches?
      end

      def licenses_for(_dependency)
        raise ::Spandx::Error, :licenses_for
      end

      def resolve(_worker, *_args)
        raise ::Spandx::Error, :resolve
      end

      class << self
        include Registerable
      end
    end
  end
end
