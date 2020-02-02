# frozen_string_literal: true

require 'thor'

require 'spandx'
require 'spandx/command'
require 'spandx/commands/build'
require 'spandx/commands/scan'

module Spandx
  class CLI < Thor
    Error = Class.new(StandardError)

    desc 'version', 'spandx version'
    def version
      puts "v#{Spandx::VERSION}"
    end
    map %w[--version -v] => :version

    desc 'build', 'Build a package index'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    method_option :directory, aliases: '-d', type: :string,
                              desc: 'Directory to build index in'
    def build(*)
      if options[:help]
        invoke :help, ['build']
      else
        require_relative 'commands/build'
        Spandx::Commands::Build.new(options).execute
      end
    end

    desc 'scan LOCKFILE', 'Scan a lockfile and list dependencies/licenses'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    def scan(lockfile = nil)
      if options[:help]
        invoke :help, ['scan']
      else
        Spandx::Commands::Scan.new(lockfile, options).execute
      end
    end
  end
end
