# frozen_string_literal: true

module Spandx
  module Core
    class Printer
      def match?(_format)
        raise ::Spandx::Error, :match?
      end

      def print_header(io)
      end

      def print_line(dependency, io)
        io.puts(dependency.to_s)
      end

      def print_footer(io)
      end

      class << self
        include Registerable

        def for(format)
          find { |x| x.match?(format) } || new
        end
      end
    end

    class CsvPrinter < Printer
      def match?(format)
        format.to_sym == :csv
      end

      def print_line(dependency, io)
        io.puts(CSV.generate_line(dependency.to_a))
      end
    end

    class JsonPrinter < Printer
      def match?(format)
        format.to_sym == :json
      end

      def print_line(dependency, io)
        io.puts(Oj.dump(dependency.to_h))
      end
    end

    class TablePrinter < Printer
      def match?(format)
        format.to_sym == :table
      end

      def print_header(io)
        @dependencies = SortedSet.new
      end

      def print_line(dependency, io)
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
