# frozen_string_literal: true

module Spandx
  module Os
    module Parsers
      class Apk < ::Spandx::Core::Parser
        def match?(path)
          path.basename.fnmatch?('installed')
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
            if line.empty?
              yield package

              package = {}
            else
              line.split(':').tap { |(key, value)| package[key] = value }
            end
          end
        end

        def map_from(data, path)
          ::Spandx::Core::Dependency.new(
            path: path,
            name: data['P'],
            version: data['V'],
            meta: data.merge('license' => [data['L']])
          )
        end
      end
    end
  end
end
