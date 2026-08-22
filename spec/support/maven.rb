# frozen_string_literal: true

# Builds a gzipped Nexus index the way Maven Central publishes it: a version
# byte, a timestamp, then length-prefixed key/value fields per record.
RSpec.configure do |config|
  config.include(Module.new do
    def maven_index_for(*coordinates)
      body = [1].pack('C') + [0].pack('Q>') + coordinates.map { |gav| maven_record_for(gav) }.join
      StringIO.new.tap { |io| Zlib::GzipWriter.wrap(io) { |gz| gz.write(body) } }.string
    end

    def maven_record_for(gav)
      [1].pack('N') + maven_field('u', gav)
    end

    def maven_field(key, value)
      [1].pack('C') + [key.bytesize].pack('n') + key + [value.bytesize].pack('N') + value
    end
  end)
end
