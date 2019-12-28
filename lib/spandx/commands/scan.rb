# frozen_string_literal: true

require 'json'
require_relative '../command'

module Spandx
  class GemfileLockParser
    def parse(lockfile)
      report = { version: '1.0', packages: [] }
      parser = ::Bundler::LockfileParser.new(IO.read(lockfile))
      parser.dependencies.each do |key, dependency|
        spec = dependency.to_spec
        report[:packages].push(name: key, version: spec.version.to_s, spdx: spec.license)
      end
      report
    end
  end

  module Commands
    class Scan < Spandx::Command
      def initialize(lockfile, options)
        @lockfile = lockfile ? Pathname.new(File.expand_path(lockfile)) : nil
        @options = options
      end

      def execute(input: $stdin, output: $stdout)
        if lockfile.nil?
          output.puts 'OK'
        else
          report = parser_for(lockfile).parse(lockfile)
          output.puts JSON.pretty_generate(report)
        end
      end

      private

      attr_reader :lockfile

      def parser_for(path)
        GemfileLockParser.new
      end
    end
  end
end
