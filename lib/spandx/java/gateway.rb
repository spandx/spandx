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
        x = name.split(':')
        metadata = metadata_for(group_id: x[0], artifact_id: x[1], version: version)
        metadata.licenses
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
