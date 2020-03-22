# frozen_string_literal: true

module Spandx
  module Java
    class Metadata
      attr_reader :artifact_id, :group_id, :version, :source

      def initialize(artifact_id:, group_id:, version:, source: 'https://repo.maven.apache.org/maven2')
        @artifact_id = artifact_id
        @group_id = group_id.tr('.', '/')
        @version = version
        @source = source
      end

      def licenses
        pom.search('//licenses/license').map do |node|
          {
            name: node.at_xpath('./name').text,
            url: node.at_xpath('./url').text
          }
        end
      end

      def licenses_from(catalogue)
        licenses.map do |x|
          name = ::Spandx::Core::Content.new(x[:name])

          catalogue.find do |license|
            score = name.similarity_score(::Spandx::Core::Content.new(license.name))
            score > 85
          end
        end.compact
      end

      private

      def pom
        @pom ||= fetch
      end

      def spec_url
        [
          source,
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
  end
end
