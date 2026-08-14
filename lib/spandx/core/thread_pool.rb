# frozen_string_literal: true

module Spandx
  module Core
    class ThreadPool
      # A worker stuck in a syscall that never returns -- an un-timed-out DNS
      # lookup, in the run this was written for -- must cost its own records,
      # never the whole build.
      SHUTDOWN_TIMEOUT = 30

      def initialize(size: 1, on_exit: nil, shutdown_timeout: SHUTDOWN_TIMEOUT)
        @size = size
        @on_exit = on_exit
        @shutdown_timeout = shutdown_timeout
        @queue = SizedQueue.new(size * 4)
        @pool = size.times.map { start_worker_thread(@queue) }
      end

      def run(*args, &job)
        @queue.enq([job, args])
      end

      def done?
        @queue.empty?
      end

      # Closing the queue is what stops the workers: it drains what is left and
      # then makes `deq` return nil. Sentinel jobs cannot do this job once the
      # queue is bounded -- enqueueing one behind a backlog of wedged workers
      # would block shutdown itself.
      def shutdown
        @queue.close
        @pool.each { |thread| thread.join(@shutdown_timeout) || thread.kill }
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
          while (item = q.deq)
            perform(*item)
          end
        ensure
          @on_exit&.call
        end
      end

      # A job that raises costs one record, not the whole run.
      def perform(job, args)
        job.call(*args)
      rescue StandardError => error
        Spandx.logger.error(error)
      end
    end
  end
end
