# frozen_string_literal: true

module Spandx
  module Core
    class ThreadPool
      def initialize(size: 1, on_exit: nil)
        @size = size
        @on_exit = on_exit
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

      # A job that raises costs one record, not the whole run. `throw :exit`
      # isn't a StandardError, so shutdown still unwinds through the rescue.
      def start_worker_thread(queue)
        Thread.new(queue) do |q|
          catch(:exit) do
            loop { perform(*q.deq) }
          end
          @on_exit&.call
        end
      end

      def perform(job, args)
        job.call(*args)
      rescue StandardError => error
        Spandx.logger.error(error)
      end
    end
  end
end
