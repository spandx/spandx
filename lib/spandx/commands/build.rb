# frozen_string_literal: true

require_relative '../command'

module Spandx
  module Commands
    class Build < Spandx::Command
      def initialize(options)
        @options = options
      end

      def execute(output: $stdout)
        index = Spandx::Index.new
        gateways.each do |gateway|
          gateway.update!(index)
        end
        output.puts 'OK'
      end

      private

      def catalogue
        Spandx::Catalogue.from_git
      end

      def gateways
        [
          Spandx::Gateways::Nuget.new(catalogue: catalogue)
        ]
      end
    end
  end
end
