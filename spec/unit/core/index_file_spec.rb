# frozen_string_literal: true

RSpec.describe Spandx::Core::IndexFile do
  subject { described_class.new(data_file) }

  let(:data_file) { Spandx::Core::DataFile.new(tmp_file.path) }
  let(:tmp_file) { Tempfile.new }

  after do
    tmp_file.unlink
  end

  describe '#scan' do
    before do
      data_file.insert('activemodel', '6.0.2.2', ['Apache-2.0'])
      data_file.insert('spandx', '0.1.0', ['MIT'])
      data_file.insert('zlib', '1.1.0', ['0BSD'])

      subject.update!
    end

    specify do
      subject.scan do |x|
        expect(x.row(0)).to eql("\"activemodel\",\"6.0.2.2\",\"Apache-2.0\"\n")
      end
    end

    specify do
      subject.scan do |x|
        expect(x.row(1)).to eql("\"spandx\",\"0.1.0\",\"MIT\"\n")
      end
    end

    specify do
      subject.scan do |x|
        expect(x.row(2)).to eql("\"zlib\",\"1.1.0\",\"0BSD\"\n")
      end
    end
  end
end