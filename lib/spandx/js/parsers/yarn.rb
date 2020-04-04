# frozen_string_literal: true

module Spandx
  module Js
    module Parsers
      class Yarn < ::Spandx::Core::Parser
        START_OF_DEPENDENCY_REGEX = %r{^"?(?<name>(@|\w|-|\.|/)+)@}i.freeze

        def self.matches?(filename)
          File.basename(filename) == 'yarn.lock'
        end

        def parse(file_path)
          dependencies = []
          each_dependency_from(file_path) do |dependency|
            dependencies << dependency
          end
          dependencies
        end

        private

        def each_dependency_from(file_path)
          File.open(file_path, 'r') do |io|
            until io.eof?
              next unless (matches = io.readline.match(START_OF_DEPENDENCY_REGEX))

              yield ::Spandx::Core::Dependency.new(
                name: matches[:name].gsub(/"/, ''),
                version: io.readline.split(' ')[-1].gsub(/"/, '')
              )
            end
          end
        end
      end
    end
  end
end
