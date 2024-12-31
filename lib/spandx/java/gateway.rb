# frozen_string_literal: true

module Spandx
  module Java
    class Gateway < ::Spandx::Core::Gateway
      DEFAULT_SOURCE = 'https://repo.maven.apache.org/maven2'

      def matches?(dependency)
        dependency.package_manager == :maven
      end

      def licenses_for(dependency)
        group_id, artifact_id = dependency.name.split(':')
        metadata_for(
          group_id: group_id,
          artifact_id: artifact_id,
          version: dependency.version
        ).licenses
      end

      def metadata_for(group_id:, artifact_id:, version:)
        ::Spandx::Java::Metadata.new(
          artifact_id: artifact_id,
          group_id: group_id,
          version: version,
          source: DEFAULT_SOURCE
        )
      end
    end
  end
end
