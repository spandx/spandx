# frozen_string_literal: true

module Spandx
  module Java
    class Gateway
      DEFAULT_SOURCE = 'https://repo.maven.apache.org/maven2'

      attr_reader :http, :source

      def initialize(http: Spandx.http, source: DEFAULT_SOURCE)
        @http = http
        @source = source
      end

      def licenses_for(name, version)
        group_id, artifact_id = name.split(':')
        metadata_for(
          group_id: group_id,
          artifact_id: artifact_id,
          version: version
        ).licenses
      end

      def metadata_for(group_id:, artifact_id:, version:)
        ::Spandx::Java::Metadata.new(
          artifact_id: artifact_id,
          group_id: group_id,
          version: version,
          source: source
        )
      end
    end
  end
end
