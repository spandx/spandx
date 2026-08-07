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
          gateway.each { |url, _page| pool.run(url) { |item_url| queue.enq(fetch(item_url)) } }
        end
        queue.enq(:stop)
        saver.join
        cache.rebuild_index
      end

      private

      def fetch(url)
        ::Spandx::Dotnet::NugetGateway.new(http: ::Spandx::Core::Http.thread_local).fetch(url)
      end

      def save(queue)
        Thread.new do
          loop do
            item = queue.deq
            break if item == :stop

            cache.insert(item['id'], item['version'], [item['licenseExpression']])
          end
        end
      end
    end
  end
end
