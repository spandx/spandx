# frozen_string_literal: true

module Spandx
  module Python
    class Index
      include Enumerable

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
        queue = Queue.new
        saver = save(queue)
        ::Spandx::Core::ThreadPool.open(size: @concurrency) do |pool|
          pypi.each { |item| pool.run(item) { |dependency| queue.enq(with_license(dependency)) } }
        end
        queue.enq(:stop)
        saver.join
        cache.rebuild_index
      end

      private

      attr_reader :cache

      def with_license(dependency)
        http = ::Spandx::Core::Http.thread_local
        response = ::Spandx::Python::Source.default.lookup(dependency[:name], dependency[:version], http: http)
        dependency.merge(license: response.fetch('info', {})['license'])
      end

      def save(queue)
        Thread.new do
          loop do
            item = queue.deq
            break if item == :stop

            cache.insert(item[:name], item[:version], [item[:license]])
          end
        end
      end
    end
  end
end
