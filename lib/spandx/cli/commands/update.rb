# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      # class Index
        class Update
          def initialize(options)
            @options = options
          end

          def execute(output: $stdout)
            [
              'https://github.com/mokhan/spandx-index.git',
              'https://github.com/mokhan/spandx-rubygems.git',
              'https://github.com/spdx/license-list-data.git',
            ].each do |url|
              output.puts "Updating #{url}..."
              Spandx::Core::Database.new(url: url).update!
            end
            output.puts 'OK'
          end
        end
      # end
    end
  end
end
