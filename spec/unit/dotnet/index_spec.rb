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
      allow(gateway).to receive(:each).with(concurrency: 2).and_yield('Polaroider', '0.2.0', ['MIT'])

      subject.update!
    end

    specify { expect(cache.licenses_for('Polaroider', '0.2.0')).to match_array(['MIT']) }
  end
end
