# frozen_string_literal: true

RSpec.describe Spandx::Cli::Commands::Pull do
  subject { described_class.new(options) }

  let(:options) { {} }

  describe '#execute' do
    let(:output) { StringIO.new }

    it 'executes `spandx pull` command successfully' do
      subject.execute(output: output)
      expected = <<~OUTPUT
        Updating https://github.com/spandx/cache.git...
        Updating https://github.com/spandx/rubygems-cache.git...
        Updating https://github.com/spdx/license-list-data.git...
        OK
      OUTPUT

      expect(output.string).to eq(expected)
    end
  end
end
