# frozen_string_literal: true

RSpec.describe Spandx::Core::DataFile do
  subject { described_class.new(root_path) }

  let(:tmp_file) { Tempfile.new }
  let(:root_path) { tmp_file.path }

  after do
    tmp_file.unlink
  end

  describe '#search' do
    before do
      subject.insert('activemodel', '6.0.2.2', ['Apache-2.0'])
      subject.insert('spandx', '0.1.0', ['MIT'])
      subject.insert('zlib', '1.1.0', ['0BSD'])

      subject.index.update!
    end

    specify { expect(subject.search(name: '', version: '0.1.0')).to be_nil }
    specify { expect(subject.search(name: 'activemodel', version: '6.0.2.2')).to match_array(['activemodel', '6.0.2.2', 'Apache-2.0']) }
    specify { expect(subject.search(name: 'spandx', version: '')).to be_nil }
    specify { expect(subject.search(name: 'spandx', version: '0.1.0')).to match_array(['spandx', '0.1.0', 'MIT']) }
    specify { expect(subject.search(name: 'spandx', version: 'unknown')).to be_nil }
    specify { expect(subject.search(name: 'spandx', version: nil)).to be_nil }
    specify { expect(subject.search(name: 'unknown', version: '0.1.0')).to be_nil }
    specify { expect(subject.search(name: 'zlib', version: '1.1.0')).to match_array(['zlib', '1.1.0', '0BSD']) }
    specify { expect(subject.search(name: nil, version: '0.1.0')).to be_nil }
  end
end
