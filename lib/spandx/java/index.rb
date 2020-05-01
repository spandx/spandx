# frozen_string_literal: true

require 'tempfile'

module Spandx
  module Java
    class Index
      include Enumerable

      attr_reader :name, :source

      def initialize(directory:, source: 'https://repo.maven.apache.org/maven2')
        @directory = directory
        @source = source
        @name = 'maven'
        @cache = ::Spandx::Core::Cache.new(@name, root: directory)
      end

      def update!(catalogue:, output:)
        each do |metadata|
          name = "#{metadata.group_id}:#{metadata.artifact_id}"
          output.puts [name, metadata.version, metadata.licenses_from(catalogue)].inspect
          @cache.insert(name, metadata.version, metadata.licenses_from(catalogue))
        end
        @cache.rebuild_index
      end

      def each
        each_index_url do |url|
          each_record_from("#{source}/.index/#{url}") do |record|
            group_id, artifact_id, version = record['u'].split('|')
            yield Metadata.new(artifact_id: artifact_id, group_id: group_id, version: version)
          end
        end
      end

      private

      def each_record(io, record = {})
        until io.eof?
          field_count = io.read(4).unpack1('N').to_i # read 4 bytes for field count
          field_count.times do |_n|
            io.read(1) # flags
            key = read_key(io)
            value = read_value(io)
            record[key] = value
          end
          yield record
        end
      end

      def read_key(io)
        length = io.read(2).unpack1('n').to_i # unsigned 16 bit int
        io.read(length)
      end

      def read_value(io)
        length = io.read(4).unpack1('N').to_i
        io.read(length)
      end

      def each_record_from(url)
        stream_from(url) do |io|
          # read version
          io.read(1)
          # read timestamp
          io.read(8)
          # read records
          each_record(io) do |x|
            yield x
          end
        end
      end

      def each_index_url
        html = Nokogiri::HTML(http.get("#{source}/.index/").body)
        html.css('a[href*="nexus-maven-repository-index"]').each do |anchor|
          url = anchor['href']
          yield url if url.match(/\d+\.gz$/)
        end
      end

      def stream_from(url, path: Tempfile.new.path)
        return unless system("curl --progress-bar \"#{url}\" > #{path}", exception: true)

        Zlib::GzipReader.open(path) do |gz|
          yield gz
        end
      ensure
        File.unlink(path) if File.exist?(path)
      end

      def http
        Spandx.http
      end
    end
  end
end
