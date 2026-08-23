# frozen_string_literal: true

module Spandx
  module Python
    class Index < ::Spandx::Core::Index
      NAME = 'pypi'

      private

      def build_gateway(catalogue)
        Pypi.new(catalogue: catalogue.warm!)
      end
    end
  end
end
