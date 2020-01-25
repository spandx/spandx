# frozen_string_literal: true

module Spandx
  module Parsers
    class Csproj < Base
      class ProjectFile
        attr_reader :catalogue, :document, :nuget

        def initialize(path, nuget, catalogue)
          @catalogue = catalogue
          @nuget = nuget
          @path = path
          @dir = File.dirname(path)
          @document = Nokogiri::XML(IO.read(path))
        end

        def project_references
          document.search('//ProjectReference').map do |node|
            relative_project_path = node.attribute('Include').value.strip.tr('\\', '/')
            absolute_project_path = File.expand_path(File.join(@dir, relative_project_path))
            self.class.new(absolute_project_path, nuget, catalogue)
          end
        end

        def package_references
          document.search('//PackageReference').map do |node|
            name = attribute_for('Include', node)
            version = attribute_for('Version', node)
            Dependency.new(
              name: name,
              version: version,
              licenses: nuget.licenses_for(name, version).map { |x| catalogue[x] }
            )
          end
        end

        private

        def attribute_for(key, node)
          node.attribute(key)&.value&.strip ||
            node.at_xpath("./#{key}")&.content&.strip
        end
      end

      def self.matches?(filename)
        filename.match?(/.*\.csproj/)
      end

      def parse(lockfile)
        project_file = ProjectFile.new(lockfile, nuget, catalogue)
        (
          project_file.project_references.map(&:package_references) +
          project_file.package_references
        ).flatten.compact
      end

      def nuget
        @nuget ||= Gateways::Nuget.new
      end
    end
  end
end
