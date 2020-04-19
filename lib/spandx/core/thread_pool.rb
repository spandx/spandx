# frozen_string_literal: true

module Spandx
  module Core
    class ThreadPool
      def initialize(size: Etc.nprocessors)
        @size = size
        @jobs = Queue.new
        @pool = size.times { start_worker_thread }
      end

      def schedule(*args, &block)
        @jobs << [block, args]
      end

      def shutdown
        @size.times do
          schedule { throw :exit }
        end

        @pool.map(&:join)
      end

      private

      def start_worker_thread
        Thread.new do
          catch(:exit) do
            loop do
              job, args = @jobs.deq
              job.call(*args)
            end
          end
        end
      end
    end
  end
end
