# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      class Scan
        NULL_BAR = Class.new do
          def advance(*args); end
        end.new

        attr_reader :scan_path

        def initialize(scan_path, options)
          @scan_path = ::Pathname.new(scan_path)
          @options = options
          require(options[:require]) if options[:require]
        end

        def execute(output: $stdout)
          report = ::Spandx::Core::Report.new
          each_file do |file|
            each_dependency_from(file) do |dependency|
              report.add(dependency)
            end
          end
          output.puts(format(report.to(@options[:format])))
        end

        private

        def each_file
          Spandx::Core::PathTraversal
            .new(scan_path, recursive: @options['recursive'])
            .each { |file| yield file }
        end

        def each_dependency_from(file)
          dependencies = ::Spandx::Core::Parser.for(file).parse(file)
          with_progress(title_for(file), dependencies.size) do |bar|
            ::Spandx::Core::Concurrent
              .map(dependencies) { |dependency| enhance(dependency) }
              .each do |dependency|
              bar.advance(1)
              yield dependency
            end
          end
        end

        def format(output)
          Array(output).map(&:to_s)
        end

        def enhance(dependency)
          ::Spandx::Core::Plugin
            .all
            .inject(dependency) { |memo, plugin| plugin.enhance(memo) }
        end

        def title_for(file)
          "#{file} [:bar, :elapsed] :percent"
        end

        def with_progress(title, total)
          yield @options[:show_progress] ? TTY::ProgressBar.new(title, total: total) : NULL_BAR
        end
      end
    end
  end
end
