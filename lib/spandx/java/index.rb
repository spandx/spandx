# frozen_string_literal: true
require 'tempfile'

module Spandx
  module Java
    class Index
      attr_reader :source

      def initialize(directory:)
        @directory = directory
        @source = 'https://repo.maven.apache.org/maven2/.index/'
      end

      def update!(catalogue:, output:)
        each do |record|
          puts record.inspect
        end
      end

      def each
        html = Nokogiri::HTML(http.get(source).body)
        html.css('a[href*="nexus-maven-repository-index"]').each do |anchor|
          url = anchor['href']
          if url.match(/\d+\.gz$/)
            each_record_from(URI.join(source, url).to_s) do |record|
              yield record
            end
          end
        end
      end

      private

      def each_record(io)
        until io.eof?
          record = {}
          # read 4 bytes for field count
          field_count = io.read(4).unpack("N")[0].to_i

          field_count.times do |n|
            ## read field
            io.read(1) # flags
            key = read_key(io)
            value = read_value(io)

            record[key] = value
          end
          yield record
        end
      end

      def read_key(io)
        length = io.read(2).unpack("n")[0].to_i # unsigned 16 bit int
        io.read(length)
      end

      def read_value(io)
        length = io.read(4).unpack("N")[0].to_i
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

      def stream_from(url)
        path = Tempfile.new.path
        if system("curl --progress-bar \"#{url}\" > #{path}")
          Zlib::GzipReader.open(path) do |gz|
            yield gz
          end
          File.unlink(path) if File.exist?(path)
        end
      end

      def http
        Spandx.http
      end
    end
  end
end
