# frozen_string_literal: true

module Spandx
  module Dotnet
    class Index
      DEFAULT_DIR = File.expand_path(File.join(Dir.home, '.local', 'share', 'spandx'))
      DEFAULT_CONCURRENCY = 25
      PROGRESS_INTERVAL = 100_000

      attr_reader :cache, :directory, :name, :gateway

      def initialize(directory: DEFAULT_DIR, gateway: nil, concurrency: DEFAULT_CONCURRENCY)
        @directory = directory ? File.expand_path(directory) : DEFAULT_DIR
        @name = 'nuget'
        @gateway = gateway
        @concurrency = concurrency
        @cache = Spandx::Core::Cache.new(@name, root: directory)
      end

      def update!(catalogue: ::Spandx::Spdx::Catalogue.empty, output: nil, **)
        count = 0
        started_at = monotonic_now
        gateway_for(catalogue).each_resolved(concurrency: @concurrency) do |id, version, licenses|
          cache.insert(id, version, licenses)
          count += 1
          report(output, count, started_at) if (count % PROGRESS_INTERVAL).zero?
        end
        report(output, count, started_at)
        cache.rebuild_index
      end

      private

      def gateway_for(catalogue)
        gateway || NugetGateway.new(catalogue: catalogue.warm!, concurrency: @concurrency)
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
