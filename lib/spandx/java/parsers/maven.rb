# frozen_string_literal: true

module Spandx
  module Java
    module Parsers
      class Maven < ::Spandx::Core::Parser
        def self.matches?(filename)
          File.basename(filename) == 'pom.xml'
        end

        def parse(filename)
          document = Nokogiri.XML(IO.read(filename)).tap(&:remove_namespaces!)
          document.search('//project/dependencies/dependency').map do |node|
            metadata = metadata_for(node)
            ::Spandx::Core::Dependency.new(
              name: metadata.artifact_id,
              version: metadata.version,
              licenses: metadata.licenses.map { |x| search_catalogue_for(x) }.compact
            )
          end
        end

        private

        def metadata_for(node)
          ::Spandx::Java::Metadata.new(
            artifact_id: node.at_xpath('./artifactId').text,
            group_id: node.at_xpath('./groupId').text,
            version: node.at_xpath('./version').text
          )
        end

        def search_catalogue_for(license_hash)
          name = ::Spandx::Core::Content.new(license_hash[:name])

          catalogue.find do |license|
            score = name.similarity_score(::Spandx::Core::Content.new(license.name))
            score > 85
          end
        end
      end
    end
  end
end