# frozen_string_literal: true

module Spandx
  module Js
    class Index < ::Spandx::Core::Index
      NAME = 'npm'

      private

      def build_gateway(_catalogue)
        NpmGateway.new
      end

      # yarn resolves against the same registry, so one walk fills both caches.
      def cache_names
        %w[npm yarn]
      end
    end
  end
end
