# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      class Index
        class Build < Spandx::Cli::Command
          INDEXES = {
            maven: Spandx::Java::Index,
            nuget: Spandx::Dotnet::Index,
            dotnet: Spandx::Dotnet::Index,
          }

          def initialize(options)
            @options = options
          end

          def execute(output: $stdout)
            catalogue = Spandx::Spdx::Catalogue.from_git
            indexes.each do |index|
              index.update!(catalogue: catalogue, output: output)
            end
            output.puts 'OK'
          end

          private

          def indexes
            index = INDEXES[@options[:index].to_sym]

            if index.nil?
              INDEXES.values.map { |x| x.new(directory: @options[:directory]) }
            else
              [index.new(directory: @options[:directory])]
            end
          end
        end
      end
    end
  end
end
