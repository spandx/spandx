# frozen_string_literal: true

module Spandx
  module Parsers
    class Csproj < Base
      def self.matches?(filename)
        filename.match?(/.*\.csproj/)
      end

      def parse(lockfile)
        project_file = ProjectFile.new(lockfile)
        project_file.package_references.map do |node|
          name = attribute_for('Include', node)
          version = attribute_for('Version', node)
          Dependency.new(
            name: name,
            version: version,
            licenses: nuget.licenses_for(name, version).map { |x| catalogue[x] }
          )
        end
      end

      def nuget
        @nuget ||= Gateways::Nuget.new
      end

      def attribute_for(key, node)
        node.attribute(key)&.value&.strip ||
          node.at_xpath("./#{key}")&.content&.strip
      end
    end
  end
end
require 'spandx/parsers/csproj/project_file'
