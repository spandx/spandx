# frozen_string_literal: true

RSpec.describe Spandx::Php::Index do
  subject { described_class.new(directory:, concurrency: 2) }

  let(:directory) { Dir.mktmpdir('spandx') }
  let(:cache) { Spandx::Core::Cache.new('composer', root: directory) }

  after do
    FileUtils.rm_r(directory, force: true, secure: true)
  end

  describe '#update!' do
    before do
      stub_request(:get, Spandx::Php::PackagistGateway::LIST_URL).to_return(
        status: 200,
        body: JSON.generate(packageNames: ['monolog/monolog'])
      )
      stub_request(:get, 'https://repo.packagist.org/p2/monolog/monolog.json').to_return(
        status: 200,
        body: JSON.generate(
          packages: {
            'monolog/monolog' => [
              { 'version' => '3.10.0', 'license' => ['MIT'] },
              { 'version' => '3.9.0', 'license' => ['MIT'] },
            ],
          }
        )
      )

      subject.update!
    end

    specify { expect(cache.licenses_for('monolog/monolog', '3.10.0')).to match_array(['MIT']) }
    specify { expect(cache.licenses_for('monolog/monolog', '3.9.0')).to match_array(['MIT']) }
  end
end
