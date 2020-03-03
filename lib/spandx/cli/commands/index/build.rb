# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      class Index
        class Build < Spandx::Cli::Command
          def initialize(options)
            @options = options
          end

          def execute(output: $stdout)
            catalogue = Spandx::Spdx::Catalogue.from_git
            indexes.each do |index|
              index.update!(catalogue: catalogue)
            end
            output.puts 'OK'
          end

          private

          def indexes
            [
              Spandx::Dotnet::Index.new(directory: @options[:directory])
            ]
          end
        end
      end
    end
  end
end
