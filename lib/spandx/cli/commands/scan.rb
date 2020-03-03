# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      class Scan < Spandx::Cli::Command
        attr_reader :lockfile

        def initialize(lockfile, options)
          @lockfile = lockfile ? ::Pathname.new(File.expand_path(lockfile)) : nil
          @options = options
        end

        def execute(output: $stdout)
          if lockfile.nil?
            output.puts 'OK'
          else
            report = Report.new
            Parsers.for(lockfile).parse(lockfile).each do |dependency|
              report.add(dependency)
            end
            output.puts report.to_json
          end
        end
      end
    end
  end
end
