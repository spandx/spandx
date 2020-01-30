# frozen_string_literal: true

require 'tmpdir'

RSpec.describe Spandx::Index do
  subject { described_class.new(directory) }

  let(:directory) { Dir.mktmpdir('spandx') }

  after do
    FileUtils.rm_r(directory, force: true, secure: true)
  end

  describe '#update!' do
    it 'creates an index for nuget packages' do
      VCR.use_cassette('nuget-catalogue') do
        subject.update!

        sha1 = Digest::SHA1.hexdigest('api.nuget.org/Lykke.Service.Operations.Client/2.2.8')
        expected_path = File.join(directory, sha1.scan(/../).join('/'))
        expect(Dir).to exist(expected_path)
      end
    end
  end
end
