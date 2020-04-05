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
          metadatum_from(file_path).each do |metadata|
            yield ::Spandx::Core::Dependency.new(
              name: metadata['name'],
              version: metadata['version'],
              licenses: [],
              meta: metadata
            )
          end
        end

        def metadatum_from(file_path)
          metadatum = []
          File.open(file_path, 'r') do |io|
            until io.eof?
              metadata = mapper.map_from(io)
              next if metadata.nil? || metadata.empty?

              metadatum << metadata
            end
          end
          metadatum
        end
      end
    end
  end
end
