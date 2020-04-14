# frozen_string_literal: true

module Spandx
  module Java
    module Parsers
      class Maven < ::Spandx::Core::Parser
        def matches?(filename)
          File.basename(filename) == 'pom.xml'
        end

        def parse(filename)
          document = Nokogiri.XML(IO.read(filename)).tap(&:remove_namespaces!)
          document.search('//project/dependencies/dependency').map do |node|
            map_from(node)
          end
        end

        private

        def map_from(node)
          artifact_id = node.at_xpath('./artifactId').text
          group_id = node.at_xpath('./groupId').text
          version = node.at_xpath('./version').text

          ::Spandx::Core::Dependency.new(
            package_manager: :maven,
            name: "#{group_id}:#{artifact_id}",
            version: version
          )
        end
      end
    end
  end
end
