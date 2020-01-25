# frozen_string_literal: true

module Spandx
  module Parsers
    class Csproj
      class ProjectFile
        attr_reader :catalogue, :document, :nuget

        def initialize(path)
          @path = path
          @dir = File.dirname(path)
          @document = Nokogiri::XML(IO.read(path))
        end

        def package_references
          other = project_references.map(&:package_references).flatten
          other + document.search('//PackageReference').map do |node|
            PackageReference.new(
              name: attribute_for('Include', node),
              version: attribute_for('Version', node)
            )
          end
        end

        private

        def project_references
          document.search('//ProjectReference').map do |node|
            relative_project_path = node.attribute('Include').value.strip.tr('\\', '/')
            absolute_project_path = File.expand_path(File.join(@dir, relative_project_path))
            self.class.new(absolute_project_path)
          end
        end

        def attribute_for(key, node)
          node.attribute(key)&.value&.strip ||
            node.at_xpath("./#{key}")&.content&.strip
        end
      end
    end
  end
end
