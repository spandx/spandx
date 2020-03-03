# frozen_string_literal: true

RSpec.describe Spandx::Dotnet::Index do
  subject { described_class.new(directory: directory) }

  let(:directory) { Dir.mktmpdir('spandx') }

  after do
    FileUtils.rm_r(directory, force: true, secure: true)
  end

  describe '#read' do
    let(:key) { %w[x y z] }
    let(:data) { SecureRandom.uuid }

    before do
      subject.write(key, data)
    end

    specify { expect(subject.read(key)).to eql(data) }
  end

  describe '#indexed?' do
    let(:key) { %w[x y z] }
    let(:data) { SecureRandom.uuid }

    before do
      subject.write(key, data)
    end

    specify { expect(subject).to be_indexed(key) }
  end

  describe '#update!' do
    let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }
    let(:gateway) { instance_double(Spandx::Dotnet::NugetGateway, host: 'api.nuget.org') }

    before do
      allow(Spandx::Dotnet::NugetGateway).to receive(:new).and_return(gateway)
      allow(gateway).to receive(:each)
        .and_yield({ 'id' => 'Polaroider', 'version' => '0.2.0', 'licenseExpression' => 'MIT'})

      subject.update!(catalogue: catalogue, limit: 10)
    end

    specify { expect(subject.read(['api.nuget.org', 'Polaroider', '0.2.0'])).to eql('MIT') }
  end
end
