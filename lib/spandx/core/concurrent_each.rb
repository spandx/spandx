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

      # Builds the gateway that `resolve` runs on. Gateways carrying state
      # beyond the connection -- a catalogue, a concurrency -- override this so
      # their workers are configured the same way they are.
      def with_http(http)
        self.class.new(http: http)
      end

      private

      # Runs `work` over `enum` on a pool of `concurrency` threads and returns
      # an Enumerator over the records it produces. `work` returns an array of
      # records per item, so a job may contribute none, one, or many.
      def each_concurrently(enum, concurrency:, &work)
        Enumerator.new do |yielder|
          queue = SizedQueue.new(concurrency * 4)
          error = nil
          producer = producer_for(enum, queue, concurrency: concurrency, work: work) { |x| error = x }
          drain(queue, producer) { |record| yielder << record }
          raise error if error
        end
      end

      # An early `break` on the consumer must not leave the pool running.
      # Closing the queue first is what makes that quick: the bound means
      # workers are parked in `enq` on a queue nobody is draining any more, and
      # closing it unblocks them instead of waiting out the shutdown deadline.
      def drain(queue, producer)
        while (batch = queue.deq) != STOP
          batch.each { |record| yield(record) }
        end
      ensure
        queue.close
        producer.kill
      end

      # The stop sentinel is enqueued from an `ensure` so a failure inside the
      # pool surfaces as an exception on the consumer instead of hanging it.
      def producer_for(enum, queue, concurrency:, work:)
        Thread.new do
          on_exit = -> { ::Spandx::Core::Http.close_thread_local }
          ::Spandx::Core::ThreadPool.open(size: concurrency, on_exit: on_exit) do |pool|
            enum.each { |*args| pool.run(*args) { |*a| publish(queue, work.call(*a)) } }
          end
        rescue StandardError => error
          yield(error)
        ensure
          publish(queue, STOP)
        end
      end

      # A closed queue means the consumer stopped early; the records still in
      # flight have nowhere to go, and that is not an error.
      def publish(queue, records)
        queue.enq(records)
      rescue ClosedQueueError
        nil
      end

      def discovery_enum
        enum_for(:each)
      end

      def worker
        with_http(::Spandx::Core::Http.thread_local)
      end
    end
  end
end
