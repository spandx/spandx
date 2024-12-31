# frozen_string_literal: true

RSpec.describe Spandx::Cli::Commands::Scan do
  RSpec.shared_examples 'scan' do |path|
    context "when scanning #{path}" do
      subject { described_class.new(lockfile, options) }

      let(:lockfile) { fixture_file(path) }
      let(:output) { StringIO.new }
      let(:options) { { format: 'table', recursive: true } }

      before do
        stub_request(:get, Spandx::Spdx::Gateway::URL)
          .to_return(status: 200, body: fixture_file('spdx/json/licenses.json').read)
        VCR.use_cassette(lockfile.basename) do
          subject.execute(output:)
        end
      end

      it { expect(output.string).to eql(IO.read("#{lockfile}.expected")) }
    end
  end

  include_examples 'scan', '.'
  include_examples 'scan', 'bundler/Gemfile.lock'
  include_examples 'scan', 'bundler/gems.lock'
  include_examples 'scan', 'pip/Pipfile.lock'
  include_examples 'scan', 'nuget/packages.config'
end
