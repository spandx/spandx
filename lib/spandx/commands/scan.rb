# frozen_string_literal: true

require 'json'
require_relative '../command'

module Spandx
  module Commands
    class Scan < Spandx::Command
      def initialize(lockfile, options)
        @lockfile = lockfile
        @options = options
      end

      def execute(input: $stdin, output: $stdout)
        if @lockfile.nil?
          output.puts 'OK'
        else
          full_path = File.expand_path(@lockfile)
          output.puts JSON.pretty_generate(build_report_for(full_path))
        end
      end

      private

      def build_report_for(lockfile)
        report = { version: '1.0', packages: [] }
        parser = ::Bundler::LockfileParser.new(IO.read(lockfile))
        parser.dependencies.each do |key, dependency|
          spec = dependency.to_spec
          report[:packages].push(name: key, version: spec.version.to_s, spdx: spec.license)
        end
        report
      end
    end
  end
end
