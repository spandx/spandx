# frozen_string_literal: true

module Spandx
  module Python
    class Index < ::Spandx::Core::Index
      NAME = 'pypi'

      private

      def build_gateway(_catalogue)
        Pypi.new
      end
    end
  end
end
