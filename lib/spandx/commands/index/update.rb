# frozen_string_literal: true

module Spandx
  module Commands
    class Index
      class Update < Spandx::Command
        def initialize(options)
          @options = options
        end

        def execute(output: $stdout)
          [
            'rubygems'
          ].each do |package_manager|
            Spandx::Database
              .new(url: "https://github.com/mokhan/spandx-#{package_manager}.git")
              .update!
          end
          output.puts 'OK'
        end
      end
    end
  end
end
