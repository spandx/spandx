# frozen_string_literal: true

require 'tmpdir'

RSpec.describe Spandx::Index do
  subject { described_class.new(directory) }

  let(:directory) { Dir.mktmpdir('spandx') }

  after do
    FileUtils.rm_r(directory, force: true, secure: true)
  end

  describe '#update!' do
    let(:nuget) { Spandx::Gateways::Nuget.new(catalogue: catalogue) }
    let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

    context "building the nuget index" do
      let(:package_key) { Digest::SHA1.hexdigest('api.nuget.org/Lykke.Service.Operations.Client/2.2.8') }
      let(:package_data_dir) { File.join(directory, package_key.scan(/../).join('/')) }
      let(:package_data_file) { File.join(package_data_dir, 'data') }

      before do
        VCR.use_cassette('nuget-catalogue') do
          subject.update!(nuget)
        end
      end

      specify { expect(Dir).to exist(package_data_dir) }
      specify { expect(File).to exist(package_data_file) }
      specify { expect(IO.read(package_data_file)).to eql('blah') }
    end
  end
end
