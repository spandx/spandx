# frozen_string_literal: true

RSpec.describe Spandx::Cli::Commands::Build do
  subject { described_class.new(options) }

  let(:options) { {} }

  describe '#execute' do
    let(:output) { StringIO.new }

    it 'executes `build` command successfully' do
      stub_request(:get, 'https://api.nuget.org/v3/catalog0/index.json')
        .to_return(status: 200, body: JSON.generate(items: []))

      stub_request(:get, 'https://repo.maven.apache.org/maven2/.index/')
        .to_return(status: 200, body: '<html></html>')

      stub_request(:get, 'https://pypi.org/simple/')
        .to_return(status: 200, body: '<html></html>')

      stub_request(:get, 'https://index.rubygems.org/versions')
        .to_return(status: 200, body: "created_at: 2020-12-01T00:00:35+00:00\n---\n")

      subject.execute(output:)
      expect(output.string).to eq("nuget\nmaven\npypi\nrubygems\nOK\n")
    end
  end
end
