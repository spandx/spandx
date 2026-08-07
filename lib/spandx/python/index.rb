# frozen_string_literal: true

module Spandx
  module Python
    class Index
      DEFAULT_CONCURRENCY = 25

      attr_reader :directory, :name, :pypi, :source

      def initialize(directory:, concurrency: DEFAULT_CONCURRENCY)
        @directory = directory
        @name = 'pypi'
        @source = 'https://pypi.org'
        @concurrency = concurrency
        @pypi = Pypi.new
        @cache = ::Spandx::Core::Cache.new(@name, root: directory)
      end

      def update!(*)
        pypi.each_resolved(concurrency: @concurrency) { |name, version, licenses| cache.insert(name, version, licenses) }
        cache.rebuild_index
      end

      private

      attr_reader :cache
    end
  end
end
