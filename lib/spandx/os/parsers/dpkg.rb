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

        class LineReader
          include Enumerable

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

        def each_package(io)
          @packages ||= LineReader.new(io).to_a
          @packages.each do |package|
            yield package
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
