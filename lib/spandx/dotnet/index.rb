# frozen_string_literal: true

module Spandx
  module Dotnet
    class Index
      DEFAULT_DIR = File.expand_path(File.join(Dir.home, '.local', 'share', 'spandx'))
      DEFAULT_CONCURRENCY = 25

      attr_reader :cache, :directory, :name, :gateway

      def initialize(directory: DEFAULT_DIR, gateway: Spandx::Dotnet::NugetGateway.new, concurrency: DEFAULT_CONCURRENCY)
        @directory = directory ? File.expand_path(directory) : DEFAULT_DIR
        @name = 'nuget'
        @gateway = gateway
        @concurrency = concurrency
        @cache = Spandx::Core::Cache.new(@name, root: directory)
      end

      def update!(*)
        gateway.each_resolved(concurrency: @concurrency) { |id, version, licenses| cache.insert(id, version, licenses) }
        cache.rebuild_index
      end
    end
  end
end
