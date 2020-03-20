# frozen_string_literal: true

module Spandx
  module Java
    class Index
      def initialize(directory:)
        @directory = directory
      end

      def update!(catalogue:, output:); end
    end
  end
end
