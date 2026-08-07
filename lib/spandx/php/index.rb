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
        queue = Queue.new
        saver = save(queue)
        on_exit = -> { ::Spandx::Core::Http.close_thread_local }
        ::Spandx::Core::ThreadPool.open(size: @concurrency, on_exit: on_exit) do |pool|
          gateway.each { |package_name| pool.run(package_name) { |name| fetch_package(name, queue) } }
        end
        queue.enq(:stop)
        saver.join
        cache.rebuild_index
      end

      private

      attr_reader :cache

      def fetch_package(name, queue)
        gw = ::Spandx::Php::PackagistGateway.new(http: ::Spandx::Core::Http.thread_local)
        gw.metadata_for(name).each do |version|
          queue.enq(name: name, version: version['version'], licenses: Array(version['license']))
        end
      end

      def save(queue)
        Thread.new do
          loop do
            item = queue.deq
            break if item == :stop

            cache.insert(item[:name], item[:version], item[:licenses])
          end
        end
      end
    end
  end
end
