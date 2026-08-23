# frozen_string_literal: true

RSpec.describe Spandx::Core::DataFile do
  subject { described_class.new(tmp_file.path) }

  let(:tmp_file) { Tempfile.new }

  after { tmp_file.unlink }

  describe '#insert' do
    # IndexFile addresses records by the byte offset of each line, so a value
    # holding a newline splits one record in two and misaligns every offset
    # after it. rubygems publishes exactly such a license.
    context 'when a license contains a newline' do
      let(:license) { "GPL 3 if you're compiling against Readline,\n  otherwise MIT" }

      before { subject.insert('readline_buffer', '1.0.0', [license]) }

      it 'writes one line' do
        expect(tmp_file.read.lines.count).to be(1)
      end

      it 'keeps the text on that line' do
        expect(subject.first).to eql(
          ['readline_buffer', '1.0.0', "GPL 3 if you're compiling against Readline, otherwise MIT"]
        )
      end
    end

    context 'when a name or version contains a newline' do
      before { subject.insert("odd\nname", "1.0\n0", ['MIT']) }

      it 'writes one line' do
        expect(tmp_file.read.lines.count).to be(1)
      end
    end

    context 'with ordinary values' do
      before { subject.insert('spandx', '0.1.0', ['MIT']) }

      it { expect(subject.first).to eql(['spandx', '0.1.0', 'MIT']) }
    end
  end
end
