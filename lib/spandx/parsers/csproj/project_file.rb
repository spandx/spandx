# frozen_string_literal: true

module Spandx
  module Parsers
    class Csproj
      class ProjectFile
        attr_reader :catalogue, :document, :nuget

        def initialize(path)
          @path = path
          @dir = File.dirname(path)
          @document = Nokogiri::XML(IO.read(path)).tap(&:remove_namespaces!)
        end

        def package_references
          project_references.flat_map(&:package_references) +
            references('GlobalPackageReference') +
            references('PackageReference')
        end

        private

        def project_references
          document.search('//ProjectReference').map do |node|
            relative_project_path = node.attribute('Include').value.strip.tr('\\', '/')
            absolute_project_path = File.expand_path(File.join(@dir, relative_project_path))
            self.class.new(absolute_project_path)
          end
        end

        def references(key)
          document.search("//#{key}").map do |node|
            PackageReference.new(
              name: name_from(node),
              version: attribute_for('Version', node)
            )
          end
        end

        def name_from(node)
          attribute_for('Include', node) ||
            attribute_for('Update', node)
        end

        def attribute_for(key, node)
          node.attribute(key)&.value&.strip ||
            node.at_xpath("./#{key}")&.content&.strip
        end
      end
    end
  end
end
