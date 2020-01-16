# frozen_string_literal: true

module Spandx
  module Commands
    class Scan < Spandx::Command
      attr_reader :lockfile

      def initialize(lockfile, options)
        @lockfile = lockfile ? Pathname.new(File.expand_path(lockfile)) : nil
        @options = options
      end

      def execute(output: $stdout)
        if lockfile.nil?
          output.puts 'OK'
        else
          report = Parsers.for(lockfile).parse(lockfile)
          output.puts report.to_json
        end
      end
    end
  end
end
