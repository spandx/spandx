# frozen_string_literal: true

module Spandx
  module Python
    class Index
      include Enumerable

      attr_reader :directory, :name, :pypi, :source

      def initialize(directory:)
        @directory = directory
        @name = 'pypi'
        @source = 'https://pypi.org'
        @pypi = Pypi.new
        @cache = ::Spandx::Core::Cache.new(@name, root: directory)
      end

      def update!(*)
        queue = Queue.new
        [fetch(queue), save(queue)].each(&:join)
        cache.rebuild_index
      end

      private

      attr_reader :cache

      def fetch(queue)
        Thread.new do
          pypi.each do |dependency|
            queue.enq(dependency)
          end
          queue.enq(:stop)
        end
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
