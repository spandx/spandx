# frozen_string_literal: true

module Spandx
  module Core
    class CsvPrinter < Printer
      def match?(format)
        format.to_sym == :csv
      end

      def print_line(dependency, io)
        io.puts(CSV.generate_line(dependency.to_a))
      end
    end
  end
end
