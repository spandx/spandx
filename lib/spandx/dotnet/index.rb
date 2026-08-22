# frozen_string_literal: true

module Spandx
  module Dotnet
    class Index < ::Spandx::Core::Index
      NAME = 'nuget'

      private

      # The catalogue resolves license urls to SPDX ids while indexing, so it
      # is warmed once here rather than lazily inside the worker threads.
      def build_gateway(catalogue)
        NugetGateway.new(catalogue: catalogue.warm!, concurrency: concurrency)
      end
    end
  end
end
