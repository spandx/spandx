# frozen_string_literal: true

module Spandx
  module Dotnet
    class Index
      DEFAULT_DIR = File.expand_path(File.join(Dir.home, '.local', 'share', 'spandx'))
      attr_reader :cache, :directory, :name, :gateway

      def initialize(directory: DEFAULT_DIR, gateway: Spandx::Dotnet::NugetGateway.new)
        @directory = directory ? File.expand_path(directory) : DEFAULT_DIR
        @name = 'nuget'
        @gateway = gateway
        @cache = Spandx::Core::Cache.new(@name, root: directory)
      end

      def update!(*)
        queue = Queue.new
        [fetch(queue), save(queue)].each(&:join)
        cache.rebuild_index
      end

      private

      def fetch(queue)
        Thread.new do
          gateway.each do |item|
            queue.enq(item)
          end
          queue.enq(:stop)
        end
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
