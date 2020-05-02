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
          report = ::Spandx::Core::Report.new

          traversal = Spandx::Core::PathTraversal.new(scan_path, recursive: @options['recursive'])
          traversal.each do |file|
            each_dependency_from(file) do |dependency|
              report.add(dependency)
            end
          end
          output.puts(format(report.to(@options[:format])))
        end

        private

        def each_dependency_from(file)
          ::Spandx::Core::Parser
            .for(file)
            .parse(file)
            .map { |dependency| enhance(dependency) }
            .each { |dependency| yield dependency }
        end

        def format(output)
          Array(output).map(&:to_s)
        end

        def enhance(dependency)
          ::Spandx::Core::Plugin
            .all
            .inject(dependency) { |memo, plugin| plugin.enhance(memo) }
        end
      end
    end
  end
end
