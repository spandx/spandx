# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      class Scan
        include Spandx::Core
        attr_reader :scan_path

        def initialize(scan_path, options)
          @scan_path = ::Pathname.new(scan_path)
          @options = options
          require(options[:require]) if options[:require]
        end

        def execute(output: $stdout)
          with_printer(output) do |printer|
            each_dependency do |dependency|
              Async do
                printer.print_line(Plugin.enhance(dependency), output)
              end
            end
          end
        end

        private

        def each_file
          PathTraversal
            .new(scan_path, recursive: @options[:recursive])
            .each { |file| yield file }
        end

        def each_dependency
          each_file do |file|
            Parser.parse(file).each do |dependency|
              yield dependency
            end
          end
        end

        def format(output)
          Array(output).map(&:to_s)
        end

        def with_printer(output)
          printer = ::Spandx::Cli::Printer.for(@options[:format])
          printer.print_header(output)
          yield printer
        ensure
          printer.print_footer(output)
        end
      end
    end
  end
end
