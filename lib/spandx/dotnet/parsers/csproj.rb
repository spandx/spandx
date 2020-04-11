# frozen_string_literal: true

module Spandx
  module Dotnet
    module Parsers
      class Csproj < ::Spandx::Core::Parser
        def self.matches?(filename)
          ['.csproj', '.props'].include?(File.extname(filename))
        end

        def parse(lockfile)
          ProjectFile
            .new(lockfile)
            .package_references
            .map { |x| map_from(x) }
        end

        private

        def map_from(package_reference)
          ::Spandx::Core::Dependency.new(
            package_manager: :nuget,
            name: package_reference.name,
            version: package_reference.version,
            meta: package_reference
          )
        end
      end
    end
  end
end
