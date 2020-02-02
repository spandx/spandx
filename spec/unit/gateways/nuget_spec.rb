# frozen_string_literal: true

RSpec.describe Spandx::Gateways::Nuget do
  subject { described_class.new(catalogue: catalogue) }

  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

  describe '#licenses_for' do
    context 'when the package specifies the license using an expression' do
      specify do
        VCR.use_cassette('jive-0.1.0') do
          expect(subject.licenses_for('jive', '0.1.0')).to match_array(['MIT'])
        end
      end
    end

    pending 'when the package specifies the license using a file'
    pending 'when the package specifies the license using a url'
  end

  describe '#update!' do
    let(:package_key) { Digest::SHA1.hexdigest('api.nuget.org/SpecFlow.Contrib.Variants/1.1.2') }
    let(:package_data_dir) { File.join(directory, package_key.scan(/../).join('/')) }
    let(:package_data_file) { File.join(package_data_dir, 'data') }
    let(:index) { instance_double(Spandx::Index, indexed?: false, write: nil) }

    before do
      VCR.use_cassette('nuget-catalogue') do
        subject.update!(index, limit: 10)
      end
    end

    pending { expect(index).to have_received(:write).with(['api.nuget.org', 'SpecFlow.Contrib.Variants', '1.1.2'], 'MIT') }
  end
end
