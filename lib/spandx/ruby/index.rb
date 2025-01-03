# frozen_string_literal: true

module Spandx
  module Ruby
    class Index
      include Enumerable

      attr_reader :directory, :name, :rubygems

      def initialize(directory:)
        @directory = directory
        @name = 'rubygems'
        @cache = ::Spandx::Core::Cache.new(@name, root: directory)
        @rubygems = ::Spandx::Ruby::Gateway.new
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
          rubygems.each do |item|
            queue.enq(
              item.merge(
                licenses: rubygems.licenses(item[:name], item[:version])
              )
            )
          end
          queue.enq(:stop)
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
