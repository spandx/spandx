# frozen_string_literal: true

module Spandx
  module Os
    module Parsers
      class Dpkg < ::Spandx::Core::Parser
        class LineReader
          attr_reader :io

          def initialize(io)
            @io = io
          end

          def each
            yield read_package(io, Hash.new(''), nil) until io.eof?
          end

          private

          def read_package(io, package, last_key)
            return package if io.eof?

            line = io.readline.chomp
            return package if line.empty?

            key, value = split(line, last_key)
            package[key] += value
            read_package(io, package, key)
          end

          def split(line, last_key)
            if last_key && line.start_with?(' ')
              [last_key, line]
            else
              key, *rest = line.split(':')
              value = rest&.join(':')&.strip
              [key, value]
            end
          end
        end

        def match?(path)
          path.basename.fnmatch?('status')
        end

        def parse(lockfile)
          [].tap do |items|
            lockfile.open(mode: 'r') do |io|
              LineReader.new(io).each do |data|
                items.push(map_from(data, lockfile.to_s))
              end
            end
          end
        end

        private

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
