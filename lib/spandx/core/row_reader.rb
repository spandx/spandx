# frozen_string_literal: true

module Spandx
  module Core
    class RowReader
      attr_reader :io, :index

      def initialize(io, index)
        @io = io
        @index = index
      end

      def row(number)
        io.seek(index.position_for(number))
        io.gets
      end
    end
  end
end
