# frozen_string_literal: true

RSpec.describe Spandx::Java::Index do
  subject { described_class.new(directory:, concurrency: 2) }

  let(:directory) { Dir.mktmpdir('spandx') }
  let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }
  let(:cache) { Spandx::Core::Cache.new('maven', root: directory) }

  after { FileUtils.rm_r(directory, force: true, secure: true) }

  before do
    stub_request(:get, "https://repo.maven.apache.org/maven2/.index/#{Spandx::Java::Gateway::FULL_INDEX}")
      .to_return(status: 200, body: maven_index_for('org.example|spandx|1.0.0'))
    stub_request(:get, 'https://repo.maven.apache.org/maven2/org/example/spandx/1.0.0/spandx-1.0.0.pom').to_return(
      status: 200,
      body: '<project><licenses><license><name>MIT</name></license></licenses></project>'
    )

    subject.update!(catalogue:, output: StringIO.new)
  end

  # The scan side builds a dependency name as "<groupId>:<artifactId>" with dots
  # (Java::Parsers::Maven). Keying the index off Metadata#group_id, which is
  # slashed for building pom urls, meant every cache lookup missed.
  it 'keys the cache the way a scan looks it up' do
    expect(cache.licenses_for('org.example:spandx', '1.0.0')).to eql(['MIT'])
  end
end
