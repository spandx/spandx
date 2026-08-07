# frozen_string_literal: true

module Spandx
  module Dotnet
    class Index
      DEFAULT_DIR = File.expand_path(File.join(Dir.home, '.local', 'share', 'spandx'))
      DEFAULT_CONCURRENCY = 25

      attr_reader :cache, :directory, :name, :gateway

      def initialize(directory: DEFAULT_DIR, gateway: Spandx::Dotnet::NugetGateway.new, concurrency: DEFAULT_CONCURRENCY)
        @directory = directory ? File.expand_path(directory) : DEFAULT_DIR
        @name = 'nuget'
        @gateway = gateway
        @concurrency = concurrency
        @cache = Spandx::Core::Cache.new(@name, root: directory)
      end

      def update!(*)
        queue = Queue.new
        saver = save(queue)
        on_exit = -> { ::Spandx::Core::Http.close_thread_local }
        ::Spandx::Core::ThreadPool.open(size: @concurrency, on_exit: on_exit) do |pool|
          gateway.each { |id, version, _page| pool.run(id, version) { |i, v| queue.enq(fetch(i, v)) } }
        end
        queue.enq(:stop)
        saver.join
        cache.rebuild_index
      end

      private

      def fetch(id, version)
        gw = ::Spandx::Dotnet::NugetGateway.new(http: ::Spandx::Core::Http.thread_local)
        { 'id' => id, 'version' => version, 'licenses' => gw.licenses(id, version) }
      end

      def save(queue)
        Thread.new do
          loop do
            item = queue.deq
            break if item == :stop

            cache.insert(item['id'], item['version'], item['licenses'])
          end
        end
      end
    end
  end
end
