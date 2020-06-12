# frozen_string_literal: true

module Spandx
  module Core
    class ThreadPool
      def initialize(size: Etc.nprocessors)
        @size = size
        @queue = Queue.new
        @pool = size.times.map { start_worker_thread(@queue) }
      end

      def run(*args, &job)
        @queue.enq([job, args])
      end

      def done?
        @queue.empty?
      end

      def shutdown
        @size.times do
          run { throw :exit }
        end

        @pool.map(&:join)
      end

      def self.open(**args)
        pool = new(**args)
        yield pool
      ensure
        pool.shutdown
      end

      private

      def start_worker_thread(queue)
        Thread.new(queue) do |q|
          catch(:exit) do
            loop do
              job, args = q.deq
              job.call(args)
            end
          end
        end
      end
    end
  end
end
