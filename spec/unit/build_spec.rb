# frozen_string_literal: true

RSpec.describe Spandx::Commands::Build do
  describe '#execute' do
    subject { described_class.new(options) }

    let(:output) { StringIO.new }
    let(:options) { {} }

    it 'executes `build` command successfully' do
      stub_request(:get, 'https://api.nuget.org/v3/catalog0/index.json')
        .to_return(status: 200, body: JSON.generate(items: []))
      subject.execute(output: output)
      expect(output.string).to eq("OK\n")
    end
  end
end
