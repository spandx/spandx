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

      def each_resolved(concurrency: DEFAULT_CONCURRENCY)
        queue = Queue.new
        dispatcher = dispatch(queue, concurrency: concurrency)
        loop do
          record = queue.deq
          break if record == :stop

          yield(*record)
        end
        dispatcher.join
      end

      private

      def dispatch(queue, concurrency:)
        on_exit = -> { ::Spandx::Core::Http.close_thread_local }
        Thread.new do
          ::Spandx::Core::ThreadPool.open(size: concurrency, on_exit: on_exit) do |pool|
            discovery_enum.each { |*args| pool.run(*args) { |*a| resolve(worker, *a) { |*record| queue.enq(record) } } }
          end
          queue.enq(:stop)
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
