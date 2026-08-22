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

      # The two halves a gateway supplies to `ConcurrentEach#each`:
      # `each_package` yields whatever is cheap to enumerate -- a name, an id, a
      # coordinate -- and `resolve` turns one of those into the
      # (name, version, licenses) records it stands for.
      def each_package
        raise ::Spandx::Error, :each_package
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
