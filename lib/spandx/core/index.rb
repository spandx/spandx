# frozen_string_literal: true

module Spandx
  module Core
    # Every package manager is indexed the same way: walk the gateway's own
    # enumeration across a pool of workers, and write each resolved
    # (name, version, licenses) record to a cache.
    #
    # Adding a package manager means writing a gateway that implements
    # `each_package` and `resolve`, then a subclass that names itself and
    # builds it:
    #
    #   class Index < ::Spandx::Core::Index
    #     NAME = 'composer'
    #
    #     private
    #
    #     def build_gateway(_catalogue) = PackagistGateway.new
    #   end
    class Index
      DEFAULT_CONCURRENCY = 25
      PROGRESS_INTERVAL = 100_000

      attr_reader :directory, :concurrency

      def initialize(directory:, concurrency: DEFAULT_CONCURRENCY, gateway: nil)
        @directory = directory
        @concurrency = concurrency
        @gateway = gateway
        @caches = cache_names.map { |cache_name| Cache.new(cache_name, root: directory) }
      end

      def name
        self.class::NAME
      end

      def update!(catalogue: ::Spandx::Spdx::Catalogue.empty, output: nil, **)
        count = 0
        started_at = monotonic_now
        gateway_for(catalogue).each(concurrency: concurrency) do |name, version, licenses|
          insert(name, version, licenses)
          count += 1
          report(output, count, started_at) if (count % PROGRESS_INTERVAL).zero?
        end
        report(output, count, started_at)
        @caches.each(&:rebuild_index)
      end

      def gateway
        @gateway ||= build_gateway(::Spandx::Spdx::Catalogue.empty)
      end

      private

      # The catalogue is passed for the gateways that resolve license urls
      # while indexing; most ignore it.
      def build_gateway(_catalogue)
        raise ::Spandx::Error, :build_gateway
      end

      # Most package managers write one cache. npm writes npm and yarn.
      def cache_names
        [name]
      end

      def gateway_for(catalogue)
        @gateway || build_gateway(catalogue)
      end

      def insert(name, version, licenses)
        @caches.each { |cache| cache.insert(name, version, licenses) }
      end

      # A build that can stall silently for hours is worse than a slow one.
      def report(output, count, started_at)
        elapsed = (monotonic_now - started_at).round
        output&.puts("#{name}: #{count} rows, #{elapsed}s, #{count / [elapsed, 1].max} rows/s")
      end

      def monotonic_now
        Process.clock_gettime(Process::CLOCK_MONOTONIC)
      end
    end
  end
end
