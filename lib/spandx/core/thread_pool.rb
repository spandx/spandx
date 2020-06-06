# frozen_string_literal: true

module Spandx
  module Core
    class ThreadPool
      def initialize(size: Etc.nprocessors, show_progress: true)
        @size = size
        @queue = Queue.new
        @pool = size.times.map { start_worker_thread(@queue) }
        @spinner = show_progress ? Spinner.new : Spinner::NULL
      end

      def run(message, *args, &block)
        @queue.enq([message, block, args])
      end

      def done?
        @queue.empty?
      end

      def shutdown
        @size.times do
          run('Bye') { throw :exit }
        end

        @pool.map(&:join)
        @spinner.stop
      end

      def self.open(*args)
        pool = new(*args)
        yield pool
      ensure
        pool.shutdown
      end

      private

      def start_worker_thread(queue)
        Thread.new(queue) do |q|
          catch(:exit) do
            loop do
              message, job, args = q.deq
              @spinner.spin(message)
              job.call(*args)
            end
          end
        end
      end
    end
  end
end
