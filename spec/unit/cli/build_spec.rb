# frozen_string_literal: true

RSpec.describe Spandx::Cli::Commands::Build do
  subject { described_class.new(options) }

  let(:options) { {} }

  describe '#execute' do
    let(:output) { StringIO.new }

    it 'executes `build` command successfully' do
      stub_request(:get, Spandx::Php::PackagistGateway::LIST_URL)
        .to_return(status: 200, body: JSON.generate(packageNames: []))

      stub_request(:get, 'https://api.nuget.org/v3/catalog0/index.json')
        .to_return(status: 200, body: JSON.generate(items: []))

      stub_request(:get, "https://repo.maven.apache.org/maven2/.index/#{Spandx::Java::Gateway::FULL_INDEX}")
        .to_return(status: 200, body: maven_index_for)

      stub_request(:get, "#{Spandx::Js::NpmGateway::ALL_DOCS_URL}?limit=1000")
        .to_return(status: 200, body: JSON.generate(rows: []))

      stub_request(:get, 'https://pypi.org/simple/')
        .to_return(status: 200, body: '<html></html>')

      stub_request(:get, 'https://index.rubygems.org/versions')
        .to_return(status: 200, body: "created_at: 2020-12-01T00:00:35+00:00\n---\n")

      subject.execute(output:)
      expect(output.string).to eq(
        %w[composer nuget maven npm pypi rubygems]
          .map { |name| "#{name}\n#{name}: 0 rows, 0s, 0 rows/s\n" }
          .join + "OK\n"
      )
    end
  end
end
