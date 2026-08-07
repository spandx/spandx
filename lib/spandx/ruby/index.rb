# frozen_string_literal: true

module Spandx
  module Ruby
    class Index
      DEFAULT_CONCURRENCY = 25

      attr_reader :directory, :name, :rubygems

      def initialize(directory:, concurrency: DEFAULT_CONCURRENCY)
        @directory = directory
        @name = 'rubygems'
        @concurrency = concurrency
        @cache = ::Spandx::Core::Cache.new(@name, root: directory)
        @rubygems = ::Spandx::Ruby::Gateway.new
      end

      def update!(*)
        rubygems.each_resolved(concurrency: @concurrency) { |name, version, licenses| cache.insert(name, version, licenses) }
        cache.rebuild_index
      end

      private

      attr_reader :cache
    end
  end
end
