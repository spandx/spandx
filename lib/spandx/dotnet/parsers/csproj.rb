# frozen_string_literal: true

module Spandx
  module Dotnet
    module Parsers
      class Csproj < ::Spandx::Core::Parser
        def match?(path)
          ['.csproj', '.props'].include?(path.extname)
        end

        def parse(path)
          ProjectFile
            .new(path)
            .package_references
            .map { |x| map_from(path, x) }
        end

        private

        def map_from(path, package_reference)
          ::Spandx::Core::Dependency.new(
            path: path,
            name: package_reference.name,
            version: package_reference.version,
            meta: package_reference
          )
        end
      end
    end
  end
end
