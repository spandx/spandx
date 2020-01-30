require 'tmpdir'

RSpec.describe Spandx::Index do
  subject { described_class.new(directory) }
  let(:directory) { Dir.mktmpdir('spandx') }

  after do
    FileUtils.rm_r(directory, force: true, secure: true)
  end

  describe "#update!" do
    let(:nuget) {  }

    it 'creates an index for nuget packages' do
      subject.update!(nuget)
    end
  end
end
