# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      class Scan < Spandx::Cli::Command
        attr_reader :scan_path

        def initialize(scan_path, options)
          @scan_path = ::Pathname.new(scan_path)
          @options = options
        end

        def execute(output: $stdout)
          report = ::Spandx::Core::Report.new
          each_file_in(scan_path) do |file|
            each_dependency_from(file) do |dependency|
              report.add(dependency)
            end
          end
          output.puts(format(report.to(@options[:format])))
        end

        private

        def recursive?
          @options['recursive']
        end

        def each_file_in(dir, &block)
          files = File.directory?(dir) ? Dir.glob(File.join(dir, '*')) : [dir]
          files.each do |file|
            if File.directory?(file)
              each_file_in(file, &block) if recursive?
            else
              block.call(file)
            end
          end
        end

        def each_dependency_from(file)
          ::Spandx::Core::Parser
            .for(file)
            .parse(file)
            .each { |dependency| yield dependency }
        end

        def format(output)
          Array(output).map(&:to_s)
        end
      end
    end
  end
end
