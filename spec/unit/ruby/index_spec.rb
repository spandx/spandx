# frozen_string_literal: true

RSpec.describe Spandx::Ruby::Index do
  subject { described_class.new(directory:, concurrency: 2) }

  let(:directory) { Dir.mktmpdir('spandx') }
  let(:cache) { Spandx::Core::Cache.new('rubygems', root: directory) }

  after do
    FileUtils.rm_r(directory, force: true, secure: true)
  end

  describe '#update!' do
    before do
      stub_request(:get, 'https://index.rubygems.org/versions').to_return(
        status: 200,
        body: "created_at: 2024-01-01T00:00:00+00:00\n---\nspandx 0.0.0 abc123\nbolt 0.2.0 def456\n"
      )
      stub_request(:get, 'https://rubygems.org/api/v1/versions/spandx.json')
        .to_return(status: 200, body: JSON.generate([{ 'number' => '0.0.0', 'licenses' => ['MIT'] }]))
      stub_request(:get, 'https://rubygems.org/api/v1/versions/bolt.json')
        .to_return(status: 200, body: JSON.generate([{ 'number' => '0.2.0', 'licenses' => ['Apache-2.0'] }]))

      subject.update!
    end

    specify { expect(cache.licenses_for('spandx', '0.0.0')).to match_array(['MIT']) }
    specify { expect(cache.licenses_for('bolt', '0.2.0')).to match_array(['Apache-2.0']) }
  end
end
