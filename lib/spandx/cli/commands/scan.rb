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
              Spandx.logger.debug(file)
              block.call(file)
            end
          end
        end

        def each_dependency_from(file)
          res = ::Spandx::Core::Parser
            .for(file)
            .parse(file)
          bar = TTY::ProgressBar.new('Add data to dependencies [:bar, :elapsed] :percent', total: res.size)
          res.map do |dependency|
            bar.advance(1)
            enhance(dependency)
          end.each { |dependency| yield dependency } # rubocop:disable Style/MultilineBlockChain
          # rubocop:enabled Style/MultilineBlockChain
        rescue StandardError => error
          Spandx.logger.error(error)
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
