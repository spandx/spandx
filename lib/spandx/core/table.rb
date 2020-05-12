# frozen_string_literal: true

module Spandx
  module Core
    class Table
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
        io.seek(index.position_for(number))
        parse_row(io.gets)
      end

      private

      def parse_row(line)
        CsvParser.parse(line)# || CSV.parse(line)[0]
      end
    end
  end
end
