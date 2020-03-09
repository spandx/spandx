# frozen_string_literal: true

RSpec.describe Spandx::Dotnet::Index do
  subject { described_class.new(directory: directory) }

  let(:directory) { Dir.mktmpdir('spandx') }

  after do
    FileUtils.rm_r(directory, force: true, secure: true)
  end

  describe '#update!' do
    let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }
    let(:gateway) { instance_double(Spandx::Dotnet::NugetGateway, host: 'api.nuget.org') }

    before do
      allow(Spandx::Dotnet::NugetGateway).to receive(:new).and_return(gateway)
      item = { 'id' => 'Polaroider', 'version' => '0.2.0', 'licenseExpression' => 'MIT' }
      allow(gateway).to receive(:each).and_yield(item, 0)

      subject.update!(catalogue: catalogue)
    end

    specify { expect(subject.licenses_for(name: 'Polaroider', version: '0.2.0')).to match_array(['MIT']) }
  end
end
