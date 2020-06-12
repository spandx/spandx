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
              printer.print_line(enhance(dependency), output)
            end
          end
        end

        private

        def thread_count
          count = @options[:threads].to_i
          count.positive? ? count : 1
        end

        def each_file
          PathTraversal
            .new(scan_path, recursive: @options[:recursive])
            .each { |file| yield file }
        end

        def each_dependency
          with_thread_pool(size: thread_count) do |thread|
            each_file do |file|
              Parser.parse(file).each do |dependency|
                thread.run { yield dependency }
              end
            end
          end
        end

        def format(output)
          Array(output).map(&:to_s)
        end

        def enhance(dependency)
          Plugin.all.inject(dependency) do |memo, plugin|
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
          ThreadPool.open(size: size) do |pool|
            yield pool
          end
        end
      end
    end
  end
end
