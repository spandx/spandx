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

        def project_references
          document.search('//ProjectReference').map do |node|
            relative_project_path = node.attribute('Include').value.strip.tr('\\', '/')
            absolute_project_path = File.expand_path(File.join(@dir, relative_project_path))
            self.class.new(absolute_project_path)
          end
        end

        def package_references
          project_references.map(&:package_references).flatten + document.search('//PackageReference')
        end
      end
    end
  end
end
