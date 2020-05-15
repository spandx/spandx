# frozen_string_literal: true

module Spandx
  module Core
    class Concurrent
      include Enumerable

      def self.map(items, pool: Spandx.thread_pool, &block)
        queue = Queue.new

        items.each do |item|
          pool.schedule([item, block]) do |marshalled_item, callable|
            queue.enq(callable.call(marshalled_item))
          end
        end

        new(queue, items.size)
      end

      attr_reader :queue, :size

      def initialize(queue, size)
        @queue = queue
        @size = size
      end

      def each
        size.times do |_n|
          yield queue.deq
        end
      end

      def to_enum
        Enumerator.new do |yielder|
          each do |item|
            yielder.yield item
          end
        end
      end
    end
  end
end
