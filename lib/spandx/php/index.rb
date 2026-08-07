# frozen_string_literal: true

module Spandx
  module Php
    class Index
      DEFAULT_CONCURRENCY = 25

      attr_reader :directory, :name, :gateway

      def initialize(directory:, concurrency: DEFAULT_CONCURRENCY)
        @directory = directory
        @name = 'composer'
        @concurrency = concurrency
        @gateway = PackagistGateway.new
        @cache = ::Spandx::Core::Cache.new(@name, root: directory)
      end

      def update!(*)
        gateway.each_resolved(concurrency: @concurrency) { |name, version, licenses| cache.insert(name, version, licenses) }
        cache.rebuild_index
      end

      private

      attr_reader :cache
    end
  end
end
