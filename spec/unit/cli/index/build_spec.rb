# frozen_string_literal: true

RSpec.describe Spandx::Cli::Commands::Index::Build do
  subject { described_class.new(options) }

  let(:options) { {} }

  describe '#execute' do
    let(:output) { StringIO.new }

    it 'executes `build` command successfully' do
      stub_request(:get, 'https://api.nuget.org/v3/catalog0/index.json')
        .to_return(status: 200, body: JSON.generate(items: []))
      subject.execute(output: output)
      expect(output.string).to eq("OK\n")
    end
  end
end
