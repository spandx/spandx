# frozen_string_literal: true

module Spandx
  module Commands
    class Scan < Spandx::Command
      def initialize(lockfile, options)
        @lockfile = lockfile ? Pathname.new(File.expand_path(lockfile)) : nil
        @options = options
      end

      def execute(output: $stdout)
        if lockfile.nil?
          output.puts 'OK'
        else
          report = parser_for(lockfile).parse(lockfile)
          output.puts JSON.pretty_generate(report)
        end
      end

      private

      attr_reader :lockfile

      def parser_for(_path)
        Parsers::GemfileLock.new
      end
    end
  end
end
