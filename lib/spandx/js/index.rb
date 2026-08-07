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
        queue = Queue.new
        saver = save(queue)
        on_exit = -> { ::Spandx::Core::Http.close_thread_local }
        ::Spandx::Core::ThreadPool.open(size: @concurrency, on_exit: on_exit) do |pool|
          gateway.each_name { |package_name| pool.run(package_name) { |name| fetch_package(name, queue) } }
        end
        queue.enq(:stop)
        saver.join
        @npm_cache.rebuild_index
        @yarn_cache.rebuild_index
      end

      private

      def fetch_package(name, queue)
        gw = ::Spandx::Js::NpmGateway.new(http: ::Spandx::Core::Http.thread_local)
        gw.metadata_for(name).fetch('versions', {}).each_value do |version|
          queue.enq(name: version['name'] || name, version: version['version'], licenses: licenses_from(version))
        end
      end

      def licenses_from(version)
        if version['license'].is_a?(String)
          [version['license']]
        elsif version['license'].is_a?(Hash)
          [version['license']['type']].compact
        elsif version['licenses'].is_a?(Array)
          version['licenses'].filter_map { |x| x['type'] }
        else
          []
        end
      end

      def save(queue)
        Thread.new do
          loop do
            item = queue.deq
            break if item == :stop

            @npm_cache.insert(item[:name], item[:version], item[:licenses])
            @yarn_cache.insert(item[:name], item[:version], item[:licenses])
          end
        end
      end
    end
  end
end
