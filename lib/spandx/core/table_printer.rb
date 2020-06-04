# frozen_string_literal: true

module Spandx
  module Core
    class TablePrinter < Printer
      def match?(format)
        format.to_sym == :table
      end

      def print_header(_io)
        @dependencies = SortedSet.new
      end

      def print_line(dependency, _io)
        @dependencies << dependency
      end

      def print_footer(io)
        table = Terminal::Table.new(headings: ['Name', 'Version', 'Licenses', 'Location'], output: io) do |t|
          @dependencies.each do |d|
            t.add_row d.to_a
          end
        end
        io.puts(table)
      end
    end
  end
end
