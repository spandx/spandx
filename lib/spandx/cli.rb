# frozen_string_literal: true

require 'thor'

module Spandx
  # Handle the application command line parsing
  # and the dispatch to various command objects
  #
  # @api public
  class CLI < Thor
    # Error raised by this runner
    Error = Class.new(StandardError)

    desc 'version', 'spandx version'
    def version
      require_relative 'version'
      puts "v#{Spandx::VERSION}"
    end
    map %w[--version -v] => :version

    desc 'scan', 'Command description...'
    method_option :help, aliases: '-h', type: :boolean,
                         desc: 'Display usage information'
    def scan(*)
      if options[:help]
        invoke :help, ['scan']
      else
        require_relative 'commands/scan'
        Spandx::Commands::Scan.new(options).execute
      end
    end
  end
end
