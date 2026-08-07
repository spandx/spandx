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
        @default_source = ::Spandx::Python::Source.default
        @cache = ::Spandx::Core::Cache.new(@name, root: directory)
      end

      def update!(*)
        queue = Queue.new
        saver = save(queue)
        on_exit = -> { ::Spandx::Core::Http.close_thread_local }
        ::Spandx::Core::ThreadPool.open(size: @concurrency, on_exit: on_exit) do |pool|
          pypi.each { |package_source, path| pool.run(package_source, path) { |s, p| fetch_package(s, p, queue) } }
        end
        queue.enq(:stop)
        saver.join
        cache.rebuild_index
      end

      private

      attr_reader :cache

      # Runs on a pool worker: lists this package's versions and fetches each
      # version's license, all through this worker's own connection.
      def fetch_package(package_source, path, queue)
        http = ::Spandx::Core::Http.thread_local
        Pypi.new(http: http).each_version(package_source, path) do |dependency|
          queue.enq(with_license(dependency, http))
        end
      end

      def with_license(dependency, http)
        response = @default_source.lookup(dependency[:name], dependency[:version], http: http)
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
