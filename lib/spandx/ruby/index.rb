# frozen_string_literal: true

module Spandx
  module Ruby
    class Index
      include Enumerable

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
        queue = Queue.new
        saver = save(queue)
        ::Spandx::Core::ThreadPool.open(size: @concurrency, on_exit: -> { ::Spandx::Core::Http.close_thread_local }) do |pool|
          rubygems.each { |item| pool.run(item) { |dependency| queue.enq(with_licenses(dependency)) } }
        end
        queue.enq(:stop)
        saver.join
        cache.rebuild_index
      end

      private

      attr_reader :cache

      def with_licenses(dependency)
        gateway = ::Spandx::Ruby::Gateway.new(http: ::Spandx::Core::Http.thread_local)
        dependency.merge(licenses: gateway.licenses(dependency[:name], dependency[:version]))
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
