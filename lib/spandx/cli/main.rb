# frozen_string_literal: true

module Spandx
  module Cli
    class Main < Thor
      desc 'scan LOCKFILE', 'Scan a lockfile and list dependencies/licenses'
      method_option :help, aliases: '-h', type: :boolean, desc: 'Display usage information'
      method_option :recursive, aliases: '-r', type: :boolean, desc: 'Perform recursive scan', default: false
      method_option :airgap, aliases: '-a', type: :boolean, desc: 'Disable network connections', default: false
      method_option :logfile, aliases: '-l', type: :string, desc: 'Path to a logfile', default: '/dev/null'
      method_option :format, aliases: '-f', type: :string, desc: 'Format of report', default: 'table'
      method_option :pull, aliases: '-p', type: :boolean, desc: 'Pull the latest cache before the scan', default: false
      def scan(lockfile)
        if options[:help]
          invoke :help, ['scan']
        else
          Spandx.airgap = options[:airgap]
          Spandx.logger = Logger.new(options[:logfile])
          pull if options[:pull]
          Spandx::Cli::Commands::Scan.new(lockfile, options).execute
        end
      end

      desc 'pull', 'Pull the latest offline cache'
      method_option :help, aliases: '-h', type: :boolean, desc: 'Display usage information'
      def pull(*)
        if options[:help]
          invoke :help, ['pull']
        else
          Commands::Pull.new(options).execute
        end
      end

      desc 'build', 'Build a package index'
      method_option :help, aliases: '-h', type: :boolean, desc: 'Display usage information'
      method_option :directory, aliases: '-d', type: :string, desc: 'Directory to build index in', default: '.index'
      method_option :index, aliases: '-i', type: :string, desc: 'The specific index to build', default: :all
      def build(*)
        if options[:help]
          invoke :help, ['build']
        else
          Commands::Build.new(options).execute
        end
      end

      desc 'version', 'spandx version'
      def version
        puts "v#{Spandx::VERSION}"
      end
      map %w[--version -v] => :version
    end
  end
end
