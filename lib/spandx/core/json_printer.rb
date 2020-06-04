# frozen_string_literal: true

module Spandx
  module Core
    class JsonPrinter < Printer
      def match?(format)
        format.to_sym == :json
      end

      def print_line(dependency, io)
        io.puts(Oj.dump(dependency.to_h))
      end
    end
  end
end
