# frozen_string_literal: true

module Spandx
  module Java
    # https://repo.maven.apache.org/maven2/.index/
    class Index
      def initialize(directory:)
        @directory = directory
      end

      def update!(catalogue:, output:); end
    end
  end
end
