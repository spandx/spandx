# frozen_string_literal: true

require_relative '../command'

module Spandx
  module Commands
    class Scan < Spandx::Command
      def initialize(lockfile, options)
        @lockfile = lockfile
        @options = options
      end

      def execute(input: $stdin, output: $stdout)
        # Command logic goes here ...
        output.puts "OK"
      end
    end
  end
end
