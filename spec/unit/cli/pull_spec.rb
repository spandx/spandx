# frozen_string_literal: true

RSpec.describe Spandx::Cli::Commands::Pull do
  subject { described_class.new(options) }

  let(:options) { {} }

  describe '#execute' do
    let(:output) { StringIO.new }

    it 'executes `spandx pull` command successfully' do
      subject.execute(output:)

      expect(output.string).to eq(fixture_file('pull.expected').read)
    end
  end
end
