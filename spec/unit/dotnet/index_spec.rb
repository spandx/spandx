# frozen_string_literal: true

RSpec.describe Spandx::Dotnet::Index do
  subject { described_class.new(directory:, gateway:, concurrency: 2) }

  let(:gateway) { instance_double(Spandx::Dotnet::NugetGateway) }
  let(:directory) { Dir.mktmpdir('spandx') }

  after do
    FileUtils.rm_r(directory, force: true, secure: true)
  end

  describe '#update!' do
    let(:item_url) { 'https://api.nuget.org/v3/catalog0/data/2020.01.01.00.00.00/polaroider.0.2.0.json' }
    let(:item) { { 'id' => 'Polaroider', 'version' => '0.2.0', 'licenseExpression' => 'MIT' } }
    let(:cache) { Spandx::Core::Cache.new('nuget', root: directory) }

    before do
      allow(gateway).to receive(:each).and_yield(item_url, 0)
      stub_request(:get, item_url).to_return(status: 200, body: JSON.generate(item))

      subject.update!
    end

    specify { expect(cache.licenses_for('Polaroider', '0.2.0')).to match_array(['MIT']) }
  end
end
