# frozen_string_literal: true

module Spandx
  module Cli
    class Printer
      def match?(_format)
        raise ::Spandx::Error, :match?
      end

      def print_header(io); end

      def print_line(dependency, io)
        io.puts(dependency.to_s)
      end

      def print_footer(io); end

      class << self
        include Core::Registerable

        def for(format)
          find { |x| x.match?(format) } || new
        end
      end
    end
  end
end
