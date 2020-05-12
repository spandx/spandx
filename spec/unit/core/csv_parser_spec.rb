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


    context 'when parsing a line of csv that contains empty value' do
      let(:line) { '"AWSSDK.Organizations","3.3.8.12",""' }

      specify { expect(subject).to eql(['AWSSDK.Organizations', '3.3.8.12', '']) }
    end
  end
end
