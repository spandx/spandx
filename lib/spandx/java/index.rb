# frozen_string_literal: true

module Spandx
  module Java
    class Index
      def initialize(directory:)
        @directory = directory
      end

      def update!(catalogue:, output:)
        # pull latest from https://repo.maven.apache.org/maven2/.index/
      end
    end
  end
end
