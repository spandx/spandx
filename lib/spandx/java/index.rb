# frozen_string_literal: true

module Spandx
  module Java
    class Index
      def initialize(directory:)
        @directory = directory
      end

      def update!(catalogue:, output:)
        # pull latest from https://repo.maven.apache.org/maven2/.index/
        File.open(File.join(Dir.pwd, "nexus-maven-repository-index.626"), 'rb') do |io|
          # read version
          io.read(1)
          # read timestamp
          io.read(8)
          # read records
          each_record(io) do |x|
            puts x.inspect
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
    end
  end
end
