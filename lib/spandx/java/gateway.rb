# frozen_string_literal: true

module Spandx
  module Java
    # Bulk indexing walks Maven Central's Nexus index, which lists every
    # artifact but carries no license data, so `resolve` reads each pom. That is
    # one request per coordinate; there is no bulk license source to use
    # instead.
    class Gateway < ::Spandx::Core::Gateway
      DEFAULT_SOURCE = 'https://repo.maven.apache.org/maven2'
      FULL_INDEX = 'nexus-maven-repository-index.gz'
      DEFAULT_CONCURRENCY = 25

      attr_reader :catalogue, :source

      def initialize(
        http: Spandx.http,
        catalogue: ::Spandx::Spdx::Catalogue.empty,
        source: DEFAULT_SOURCE,
        concurrency: DEFAULT_CONCURRENCY
      )
        @catalogue = catalogue
        @source = source
        @concurrency = concurrency
        super(http: http)
      end

      def with_http(http)
        self.class.new(http: http, catalogue: catalogue, source: source, concurrency: @concurrency)
      end

      def matches?(dependency)
        dependency.package_manager == :maven
      end

      def licenses_for(dependency)
        group_id, artifact_id = dependency.name.split(':')
        metadata_for(group_id: group_id, artifact_id: artifact_id, version: dependency.version).licenses
      end

      # The index lists one record per artifact *file*, so the same coordinate
      # recurs for each classifier -- 6.85 records per coordinate, measured.
      # `Set#add?` is both the dedup test and the insert.
      def each_package
        seen = Set.new
        each_record_from("#{source}/.index/#{FULL_INDEX}") do |record|
          coordinate = coordinate_from(record)
          next unless coordinate && seen.add?(coordinate.join('|'))

          yield(*coordinate)
        end
      end

      def resolve(worker, group_id, artifact_id, version)
        [["#{group_id}:#{artifact_id}", version, worker.licenses_at(group_id, artifact_id, version)]]
      end

      def licenses_at(group_id, artifact_id, version)
        metadata_for(group_id: group_id, artifact_id: artifact_id, version: version)
          .licenses
          .filter_map { |license| license_id_for(license) }
      end

      def metadata_for(group_id:, artifact_id:, version:)
        ::Spandx::Java::Metadata.new(
          artifact_id: artifact_id,
          group_id: group_id,
          version: version,
          source: source,
          http: http
        )
      end

      private

      # Pure -- no network. An unrecognised name or url is stored as Maven
      # published it, and `Guess` resolves it at scan time.
      def license_id_for(license)
        name = license[:name].to_s
        url = license[:url].to_s
        catalogue[name]&.id || catalogue.find_by_url(url)&.id || presence(name) || presence(url)
      end

      def presence(value)
        value.empty? ? nil : value
      end

      # Unresolved property placeholders ("${project.version}") are not
      # coordinates and cannot be fetched.
      def coordinate_from(record)
        group_id, artifact_id, version = record['u'].to_s.split('|')
        return unless [group_id, artifact_id, version].all? { |x| x && !x.empty? && !x.include?('${') }

        [group_id, artifact_id, version]
      end

      # The index is a multi-gigabyte gzip, so it is streamed to disk rather
      # than buffered in memory the way an API response can be.
      def each_record_from(url, &block)
        path = File.join(Dir.tmpdir, "spandx-maven-index-#{Process.pid}.gz")
        return unless http.download(url, to: path)

        Zlib::GzipReader.open(path) do |io|
          io.read(1)  # format version
          io.read(8)  # timestamp
          each_record(io, &block)
        end
      ensure
        FileUtils.rm_f(path)
      end

      def each_record(io)
        until io.eof?
          record = {}
          io.read(4).unpack1('N').to_i.times do
            io.read(1) # flags
            record[read_key(io)] = read_value(io)
          end
          yield record
        end
      end

      def read_key(io)
        io.read(io.read(2).unpack1('n').to_i)
      end

      def read_value(io)
        io.read(io.read(4).unpack1('N').to_i)
      end
    end
  end
end
