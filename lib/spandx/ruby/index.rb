# frozen_string_literal: true

module Spandx
  module Ruby
    class Index < ::Spandx::Core::Index
      NAME = 'rubygems'

      private

      def build_gateway(_catalogue)
        ::Spandx::Ruby::Gateway.new
      end
    end
  end
end
