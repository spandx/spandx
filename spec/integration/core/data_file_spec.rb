# frozen_string_literal: true

RSpec.describe Spandx::Core::DataFile do
  subject { described_class.new(root_path) }

  let(:tmp_file) { Tempfile.new }
  let(:root_path) { tmp_file.path }

  after do
    tmp_file.unlink
  end

  describe "#search" do
    before do
      subject.insert('activemodel', '6.0.2.2', ['MIT'])
      subject.insert('spandx', '0.1.0', ['MIT'])
      subject.insert('zlib', '1.1.0', ['MIT'])

      subject.index.update!
    end

    it 'returns the correct result' do
      result = subject.search(name: 'spandx', version: '0.1.0')

      expect(result).to match_array(['spandx', '0.1.0', 'MIT'])
    end
  end
end
