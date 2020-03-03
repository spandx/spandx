# frozen_string_literal: true

RSpec.describe Spandx::Cli::Commands::Index::Update do
  subject { described_class.new(options) }

  let(:options) { {} }

  describe '#execute' do
    let(:output) { StringIO.new }

    it 'executes `index update` command successfully' do
      subject.execute(output: output)

      expect(output.string).to eq("OK\n")
    end
  end
end
