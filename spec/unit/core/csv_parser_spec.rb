# frozen_string_literal: true

RSpec.describe Spandx::Core::CsvParser do
  describe '.parse' do
    let(:subject) { described_class.parse(line) }

    context 'when parsing a single line of csv' do
      let(:line) { '"spandx","0.0.0","MIT"' + "\n" }

      specify { expect(subject).to eql(['spandx', '0.0.0', 'MIT']) }
    end

    context 'when parsing a line of csv that contains a `,` in the value' do
      let(:line) { '"spa,ndx","0.0.0","MIT"' + "\n" }

      specify { expect(subject).to eql(['spa,ndx', '0.0.0', 'MIT']) }
    end

    context 'when parsing a line of csv that contains empty name' do
      let(:line) { '"","0.0.0","MIT"' }

      specify { expect(subject).to eql(['', '0.0.0', 'MIT']) }
    end

    context 'when parsing a line of csv that contains empty version' do
      let(:line) { '"AWSSDK.Organizations","","MIT"' }

      specify { expect(subject).to eql(['AWSSDK.Organizations', '', 'MIT']) }
    end

    context 'when parsing a line of csv that contains empty license' do
      let(:line) { '"AWSSDK.Organizations","3.3.8.12",""' }

      specify { expect(subject).to eql(['AWSSDK.Organizations', '3.3.8.12', '']) }
    end

    context 'when parsing an invalid line of csv' do
      specify { expect(described_class.parse('invalid","3.3.8.12",""')).to be_nil }
      specify { expect(described_class.parse('"hello O\"world","0.1.0"')).to be_nil }
      specify { expect(described_class.parse('"hello O\"world","0.1.0",""')).to be_nil }
    end
  end
end
