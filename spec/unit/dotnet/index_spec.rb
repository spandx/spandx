# frozen_string_literal: true

RSpec.describe Spandx::Dotnet::Index do
  subject { described_class.new(directory:, gateway:, concurrency: 2) }

  let(:gateway) { instance_double(Spandx::Dotnet::NugetGateway) }
  let(:directory) { Dir.mktmpdir('spandx') }

  after do
    FileUtils.rm_r(directory, force: true, secure: true)
  end

  describe '#update!' do
    let(:cache) { Spandx::Core::Cache.new('nuget', root: directory) }

    before do
      allow(gateway).to receive(:each).and_yield('Polaroider', '0.2.0', 0)
      stub_request(:get, 'https://api.nuget.org/v3-flatcontainer/polaroider/0.2.0/polaroider.nuspec').to_return(
        status: 200,
        body: '<package><metadata><license type="expression">MIT</license></metadata></package>'
      )

      subject.update!
    end

    specify { expect(cache.licenses_for('Polaroider', '0.2.0')).to match_array(['MIT']) }
  end
end
