# frozen_string_literal: true

RSpec.describe Spandx::Java::Index do
  subject { described_class.new(directory:) }

  let(:directory) { Dir.mktmpdir('spandx') }
  let(:gav) { 'org.example|spandx|1.0.0' }

  def field(key, value)
    [1].pack('C') + [key.bytesize].pack('n') + key + [value.bytesize].pack('N') + value
  end

  def record_for(gav)
    [1].pack('N') + field('u', gav)
  end

  def chunk_for(*records)
    [1].pack('C') + [0].pack('Q>') + records.join
  end

  before do
    stub_request(:get, 'https://repo.maven.apache.org/maven2/.index/').to_return(
      status: 200,
      body: '<html><body><a href="nexus-maven-repository-index.1.gz">index</a></body></html>'
    )

    gz = StringIO.new.tap { |io| Zlib::GzipWriter.wrap(io) { |w| w.write(chunk_for(record_for(gav))) } }.string
    stub_request(:get, 'https://repo.maven.apache.org/maven2/.index/nexus-maven-repository-index.1.gz')
      .to_return(status: 200, body: gz)
  end

  describe '#each' do
    let(:metadata) { subject.first }

    specify { expect(metadata.group_id).to eq('org/example') }
    specify { expect(metadata.artifact_id).to eq('spandx') }
    specify { expect(metadata.version).to eq('1.0.0') }
  end

  describe '#update!' do
    let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }
    let(:cache) { Spandx::Core::Cache.new('maven', root: directory) }

    before do
      stub_request(:get, 'https://repo.maven.apache.org/maven2/org/example/spandx/1.0.0/spandx-1.0.0.pom').to_return(
        status: 200,
        body: '<project><licenses><license><name>MIT</name></license></licenses></project>'
      )

      subject.update!(catalogue:, output: StringIO.new)
    end

    specify { expect(cache.licenses_for('org/example:spandx', '1.0.0')).to eql(['MIT']) }
  end
end
