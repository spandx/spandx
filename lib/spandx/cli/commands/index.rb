# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      class Index < Thor

        namespace :index

        desc 'build', 'Build a package index'
        method_option :help, aliases: '-h', type: :boolean, desc: 'Display usage information'
        method_option :directory, aliases: '-d', type: :string, desc: 'Directory to build index in', default: '.index'
        method_option :index, aliases: '-i', type: :string, desc: 'The specific index to build', default: :all
        def build(*)
          if options[:help]
            invoke :help, ['build']
          else
            Spandx::Cli::Commands::Index::Build.new(options).execute
          end
        end

        desc 'update', 'Update the offline indexes'
        method_option :help, aliases: '-h', type: :boolean,
                             desc: 'Display usage information'
        def update(*)
          if options[:help]
            invoke :help, ['update']
          else
            Spandx::Cli::Commands::Index::Update.new(options).execute
          end
        end
      end
    end
  end
end
