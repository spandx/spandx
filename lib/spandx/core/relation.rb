# frozen_string_literal: true

module Spandx
  module Core
    class Relation
      attr_reader :io, :index

      def initialize(io, index)
        @io = io
        @index = index
      end

      def each
        size.times do |n|
          yield row(n)
        end
      end

      def size
        index.size
      end

      def row(number)
        offset = number.zero? ? 0 : index.position_for(number)
        return unless offset

        io.seek(offset)
        parse_row(io.gets)
      end

      private

      def parse_row(line)
        CsvParser.parse(line)
      end
    end
  end
end
