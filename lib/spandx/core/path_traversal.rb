# frozen_string_literal: true

module Spandx
  module Core
    class PathTraversal
      attr_reader :root

      def initialize(root, recursive: true)
        @root = root
        @recursive = recursive
      end

      def each(&block)
        each_file_in(root, &block)
      end

      private

      def recursive?
        @recursive
      end

      def each_file_in(dir, &block)
        files = File.directory?(dir) ? Dir.glob(File.join(dir, '*')) : [dir]
        files.each do |file|
          if File.directory?(file)
            each_file_in(file, &block) if recursive?
          else
            Spandx.logger.debug(file)
            block.call(file)
          end
        end
      end
    end
  end
end
