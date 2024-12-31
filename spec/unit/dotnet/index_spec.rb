# frozen_string_literal: true

RSpec.describe Spandx::Dotnet::Index do
  subject { described_class.new(directory:, gateway:) }

  let(:gateway) { instance_double(Spandx::Dotnet::NugetGateway) }
  let(:directory) { Dir.mktmpdir('spandx') }

  after do
    FileUtils.rm_r(directory, force: true, secure: true)
  end

  describe '#update!' do
    let(:item) { { 'id' => 'Polaroider', 'version' => '0.2.0', 'licenseExpression' => 'MIT' } }
    let(:cache) { Spandx::Core::Cache.new('nuget', root: directory) }

    before do
      allow(gateway).to receive(:each).and_yield(item)

      subject.update!
    end

    specify { expect(cache.licenses_for('Polaroider', '0.2.0')).to match_array(['MIT']) }
  end
end
