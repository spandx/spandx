# frozen_string_literal: true

module Spandx
  module Dotnet
    module Parsers
      class Csproj < ::Spandx::Parsers::Base
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
          Dependency.new(
            name: package_reference.name,
            version: package_reference.version,
            licenses: licenses_for(package_reference)
          )
        end

        def licenses_for(package_reference)
          nuget
            .licenses_for(package_reference.name, package_reference.version)
            .map { |x| catalogue[x] }
        end

        def nuget
          @nuget ||= NugetGateway.new(catalogue: catalogue)
        end
      end
    end
  end
end
