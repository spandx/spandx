# frozen_string_literal: true

module Spandx
  module Os
    module Parsers
      class Apk < ::Spandx::Core::Parser
        def parse(lockfile)
          path = lockfile.to_s

          [].tap do |items|
            lockfile.open(mode: "r") do |io|
              each_package(io) do |data|
                items.push(
                  ::Spandx::Core::Dependency.new(
                    path: path,
                    name: data['P'],
                    version: data['V'],
                    meta: data
                  )
                )
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
              key, value = line.split(":")
              package[key] = value
            end
          end
        end
      end
    end
  end
end
