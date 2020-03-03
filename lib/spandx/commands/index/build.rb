# frozen_string_literal: true

module Spandx
  module Commands
    class Index
      class Build < Spandx::Command
        def initialize(options)
          @options = options
        end

        def execute(output: $stdout)
          index = Spandx::Dotnet::Index.new(directory: @options[:directory])
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
            Spandx::Dotnet::NugetGateway.new(catalogue: catalogue)
          ]
        end
      end
    end
  end
end
