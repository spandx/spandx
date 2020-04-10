# frozen_string_literal: true

module Spandx
  module Core
    class Table
      def initialize
        @rows = []
        @max_justification = 0
        yield self
      end

      def <<(item)
        row = item.to_a
        new_max = row[0].size
        @max_justification = new_max + 1 if new_max > @max_justification
        @rows << row
      end

      def to_s
        @rows.map do |row|
          row.each.with_index.map do |cell, index|
            justification = index.zero? ? @max_justification : 15
            Array(cell).join(', ').ljust(justification, ' ')
          end.join
        end
      end
    end
  end
end
