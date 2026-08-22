# frozen_string_literal: true

module Spandx
  module Java
    class Index < ::Spandx::Core::Index
      NAME = 'maven'

      private

      def build_gateway(catalogue)
        Gateway.new(catalogue: catalogue.warm!, concurrency: concurrency)
      end
    end
  end
end
