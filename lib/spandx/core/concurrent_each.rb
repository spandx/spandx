# frozen_string_literal: true

module Spandx
  module Core
    # Mixed into every bulk-indexing gateway. `each_resolved` walks the
    # gateway's own cheap enumeration (`each`, by default) across a pool of
    # `concurrency` workers -- each running `resolve` against its own
    # thread-local connection -- and yields every resolved (name, version,
    # licenses) record back to the caller as workers finish.
    module ConcurrentEach
      DEFAULT_CONCURRENCY = 25
      STOP = Object.new
      private_constant :STOP

      def each_resolved(concurrency: DEFAULT_CONCURRENCY)
        each_concurrently(discovery_enum, concurrency: concurrency) { |*args| resolve(worker, *args) }
          .each { |record| yield(*record) }
      end

      private

      # Runs `work` over `enum` on a pool of `concurrency` threads and returns
      # an Enumerator over the records it produces. `work` returns an array of
      # records per item, so a job may contribute none, one, or many.
      def each_concurrently(enum, concurrency:, &work)
        Enumerator.new do |yielder|
          queue = Queue.new
          error = nil
          producer = producer_for(enum, queue, concurrency: concurrency, work: work) { |x| error = x }
          drain(queue, producer) { |record| yielder << record }
          raise error if error
        end
      end

      # An early `break` on the consumer must not leave the pool running.
      def drain(queue, producer)
        while (batch = queue.deq) != STOP
          batch.each { |record| yield(record) }
        end
      ensure
        producer.kill
      end

      # The stop sentinel is enqueued from an `ensure` so a failure inside the
      # pool surfaces as an exception on the consumer instead of hanging it.
      def producer_for(enum, queue, concurrency:, work:)
        Thread.new do
          on_exit = -> { ::Spandx::Core::Http.close_thread_local }
          ::Spandx::Core::ThreadPool.open(size: concurrency, on_exit: on_exit) do |pool|
            enum.each { |*args| pool.run(*args) { |*a| queue.enq(work.call(*a)) } }
          end
        rescue StandardError => error
          yield(error)
        ensure
          queue.enq(STOP)
        end
      end

      def discovery_enum
        enum_for(:each)
      end

      def worker
        self.class.new(http: ::Spandx::Core::Http.thread_local)
      end
    end
  end
end
