# frozen_string_literal: true

module Spandx
  module Parsers
    class Maven < Base
      class Metadata
        attr_reader :artifact_id, :group_id, :version

        def initialize(artifact_id:, group_id:, version:)
          @artifact_id = artifact_id
          @group_id = group_id.tr('.', '/')
          @version = version
        end

        def licenses
          pom.search('//licenses/license').map do |node|
            {
              name: node.at_xpath('./name').text,
              url: node.at_xpath('./url').text
            }
          end
        end

        private

        def pom
          @pom ||= fetch
        end

        def spec_url
          [
            'https://repo.maven.apache.org/maven2',
            group_id,
            artifact_id,
            version,
            "#{artifact_id}-#{version}.pom"
          ].join('/')
        end

        def fetch
          response = Spandx.http.get(spec_url)
          return unless Spandx.http.ok?(response)

          Nokogiri.XML(response.body).tap(&:remove_namespaces!)
        end
      end

      def self.matches?(filename)
        File.basename(filename) == 'pom.xml'
      end

      def parse(filename)
        document = Nokogiri.XML(IO.read(filename)).tap(&:remove_namespaces!)
        document.search('//project/dependencies/dependency').map do |node|
          metadata = metadata_for(node)
          Dependency.new(
            name: metadata.artifact_id,
            version: metadata.version,
            licenses: metadata.licenses.map { |x| search_catalogue_for(x) }.compact
          )
        end
      end

      private

      def metadata_for(node)
        Metadata.new(
          artifact_id: node.at_xpath('./artifactId').text,
          group_id: node.at_xpath('./groupId').text,
          version: node.at_xpath('./version').text
        )
      end

      def search_catalogue_for(license_hash)
        name = Content.new(license_hash[:name])

        catalogue.find do |license|
          score = name.similarity_score(Content.new(license.name))
          score > 85
        end
      end
    end
  end
end
