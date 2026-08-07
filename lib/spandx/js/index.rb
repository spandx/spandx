# frozen_string_literal: true

module Spandx
  module Js
    class Index
      DEFAULT_CONCURRENCY = 25

      attr_reader :directory, :name, :gateway

      def initialize(directory:, concurrency: DEFAULT_CONCURRENCY)
        @directory = directory
        @name = 'npm'
        @concurrency = concurrency
        @gateway = NpmGateway.new
        @npm_cache = ::Spandx::Core::Cache.new('npm', root: directory)
        @yarn_cache = ::Spandx::Core::Cache.new('yarn', root: directory)
      end

      def update!(*)
        gateway.each_resolved(concurrency: @concurrency) do |name, version, licenses|
          @npm_cache.insert(name, version, licenses)
          @yarn_cache.insert(name, version, licenses)
        end
        @npm_cache.rebuild_index
        @yarn_cache.rebuild_index
      end
    end
  end
end
