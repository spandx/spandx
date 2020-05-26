# frozen_string_literal: true

module Spandx
  module Java
    module Parsers
      class Maven < ::Spandx::Core::Parser
        def match?(path)
          path.basename.fnmatch?('pom.xml')
        end

        def parse(path)
          document = Nokogiri.XML(path.read).tap(&:remove_namespaces!)
          document.search('//project/dependencies/dependency').map do |node|
            map_from(path, node)
          end
        end

        private

        def map_from(path, node)
          artifact_id = node.at_xpath('./artifactId').text
          group_id = node.at_xpath('./groupId').text
          version = node.at_xpath('./version').text

          ::Spandx::Core::Dependency.new(
            path: path,
            name: "#{group_id}:#{artifact_id}",
            version: version
          )
        end
      end
    end
  end
end
