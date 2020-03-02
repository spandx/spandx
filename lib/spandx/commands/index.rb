# frozen_string_literal: true

module Spandx
  module Commands
    class Index < Thor
      namespace :index

      desc 'update', 'Update the offline indexes'
      method_option :help, aliases: '-h', type: :boolean,
                           desc: 'Display usage information'
      def update(*)
        if options[:help]
          invoke :help, ['update']
        else
          require_relative 'index/update'
          Spandx::Commands::Index::Update.new(options).execute
        end
      end
    end
  end
end
