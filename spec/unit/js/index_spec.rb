# frozen_string_literal: true

RSpec.describe Spandx::Js::Index do
  subject { described_class.new(directory:, concurrency: 2) }

  let(:directory) { Dir.mktmpdir('spandx') }
  let(:npm_cache) { Spandx::Core::Cache.new('npm', root: directory) }
  let(:yarn_cache) { Spandx::Core::Cache.new('yarn', root: directory) }

  after do
    FileUtils.rm_r(directory, force: true, secure: true)
  end

  describe '#update!' do
    before do
      stub_request(:get, "#{Spandx::Js::NpmGateway::ALL_DOCS_URL}?limit=1000")
        .to_return(status: 200, body: JSON.generate(rows: [{ 'id' => 'lodash' }]))
      stub_request(:get, "#{Spandx::Js::NpmGateway::REGISTRY_URL}/lodash").to_return(
        status: 200,
        body: JSON.generate(
          versions: {
            '4.17.21' => { 'name' => 'lodash', 'version' => '4.17.21', 'license' => 'MIT' },
            '0.1.0' => { 'name' => 'lodash', 'version' => '0.1.0', 'licenses' => [{ 'type' => 'MIT' }] },
          }
        )
      )

      subject.update!
    end

    specify { expect(npm_cache.licenses_for('lodash', '4.17.21')).to match_array(['MIT']) }
    specify { expect(npm_cache.licenses_for('lodash', '0.1.0')).to match_array(['MIT']) }
    specify { expect(yarn_cache.licenses_for('lodash', '4.17.21')).to match_array(['MIT']) }
  end
end
