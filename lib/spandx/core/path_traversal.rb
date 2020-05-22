# frozen_string_literal: true

module Spandx
  module Core
    class PathTraversal
      attr_reader :root

      def initialize(root, recursive: true)
        @root = Pathname.new(root)
        @recursive = recursive
      end

      def each(&block)
        each_file_in(root, &block)
      end

      private

      def recursive?
        @recursive
      end

      def each_file_in(path, &block)
        files = path.directory? ? path.children : [path]
        files.each do |file|
          if file.directory?
            each_file_in(file, &block) if recursive?
          else
            block.call(file)
          end
        end
      end
    end
  end
end
