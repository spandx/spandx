# frozen_string_literal: true

module Spandx
  module Js
    module Parsers
      class Yarn < ::Spandx::Core::Parser
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

        def mapper
          @mapper ||= YarnLockMapper.new
        end

        def each_dependency_from(file_path)
          File.open(file_path, 'r') do |io|
            until io.eof?
              item = mapper.map_from(io)
              yield item if item
            end
          end
        end
      end
    end
  end
end
