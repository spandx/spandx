# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      class Scan
        attr_reader :scan_path

        def initialize(scan_path, options)
          @scan_path = ::Pathname.new(scan_path)
          @options = options
          require(options[:require]) if options[:require]
        end

        def execute(output: $stdout)
          with_printer(output) do |printer|
            with_thread_pool(size: thread_count) do |thread|
              each_dependency do |file, dependency|
                thread.run(file, dependency, output) do |x, y|
                  printer.print_line(enhance(x), y)
                end
              end
            end
          end
        end

        private

        def thread_count
          count = @options[:threads].to_i
          count.positive? ? count : 1
        end

        def each_file
          Spandx::Core::PathTraversal
            .new(scan_path, recursive: @options[:recursive])
            .each { |file| yield file }
        end

        def each_dependency
          each_file do |file|
            ::Spandx::Core::Parser.parse(file).each do |dependency|
              yield file, dependency
            end
          end
        end

        def format(output)
          Array(output).map(&:to_s)
        end

        def enhance(dependency)
          ::Spandx::Core::Plugin.all.inject(dependency) do |memo, plugin|
            plugin.enhance(memo)
          end
        end

        def with_printer(output)
          printer = ::Spandx::Cli::Printer.for(@options[:format])
          printer.print_header(output)
          yield printer
        ensure
          printer.print_footer(output)
        end

        def with_thread_pool(size:)
          ::Spandx::Core::ThreadPool.open(size: size, show_progress: @options[:show_progress]) do |pool|
            yield pool
          end
        end
      end
    end
  end
end
