# frozen_string_literal: true

module Spandx
  module Core
    class LineIO
      def initialize(absolute_path)
        file_descriptor = IO.sysopen(absolute_path)
        @io = IO.new(file_descriptor)
        @buffer = ''
      end

      def each(&block)
        @buffer << @io.sysread(512) until @buffer.include?($INPUT_RECORD_SEPARATOR)

        line, @buffer = @buffer.split($INPUT_RECORD_SEPARATOR, 2)
        block.call(line)
        each(&block)
      rescue EOFError
        @io.close
      end
    end
  end
end
