# frozen_string_literal: true

require 'forwardable'
require 'json'
require 'thor'

require 'spandx'
require 'spandx/command'
require 'spandx/commands/scan'
require 'spandx/parsers/gemfile_lock'

module Spandx
  class CLI < Thor
    Error = Class.new(StandardError)

    desc 'version', 'spandx version'
    def version
      puts "v#{Spandx::VERSION}"
    end
    map %w[--version -v] => :version

    desc 'scan LOCKFILE', 'Command description...'
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
