# frozen_string_literal: true

require 'thor'
require 'spandx'
require 'spandx/cli/command'
require 'spandx/cli/commands/index'
require 'spandx/cli/commands/scan'

module Spandx
  class CLI < Thor
    Error = Class.new(StandardError)

    desc 'version', 'spandx version'
    def version
      puts "v#{Spandx::VERSION}"
    end
    map %w[--version -v] => :version

    register Spandx::Cli::Commands::Index, 'index', 'index [SUBCOMMAND]', 'Command description...'

    desc 'scan LOCKFILE', 'Scan a lockfile and list dependencies/licenses'
    method_option :help, aliases: '-h', type: :boolean, desc: 'Display usage information'
    method_option :recursive, aliases: '-r', type: :boolean, desc: 'Perform recursive scan', default: false
    def scan(lockfile)
      if options[:help]
        invoke :help, ['scan']
      else
        Spandx::Cli::Commands::Scan.new(lockfile, options).execute
      end
    end
  end
end
