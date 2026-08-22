# frozen_string_literal: true

module Spandx
  module Php
    class Index < ::Spandx::Core::Index
      NAME = 'composer'

      private

      def build_gateway(_catalogue)
        PackagistGateway.new
      end
    end
  end
end
