# frozen_string_literal: true

module Spandx
  module Os
    module Parsers
      class Dpkg < ::Spandx::Core::Parser
        def match?(path)
          path.basename.fnmatch?('status')
        end

        def parse(lockfile)
          path = lockfile.to_s

          [].tap do |items|
            lockfile.open(mode: 'r') do |io|
              each_package(io) do |data|
                items.push(map_from(data, path))
              end
            end
          end
        end

        private

        def each_package(io)
          package = {}

          until io.eof?
            line = io.readline.chomp
            next if line.start_with?(" ")

            if line.empty?
              yield package

              package = {}
            else
              line.split(':').tap { |(key, *value)| package[key] = value&.join(':')&.strip }
            end
          end
        end

        def map_from(data, path)
          ::Spandx::Core::Dependency.new(
            path: path,
            name: data['Package'],
            version: data['Version'],
            meta: data
          )
        end
      end
    end
  end
end
