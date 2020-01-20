# frozen_string_literal: true

RSpec.describe Spandx::Commands::Scan do
  subject { described_class.new(lockfile, options) }

  let(:output) { StringIO.new }
  let(:lockfile) { nil }
  let(:options) { {} }

  before do
    stub_request(:get, Spandx::Gateways::Spdx::URL)
      .to_return(status: 200, body: IO.read(fixture_file('spdx.json')))
  end

  it 'executes `scan` command successfully' do
    subject.execute(output: output)

    expect(output.string).to eq("OK\n")
  end

  context 'when scanning Gemfile.lock' do
    let(:lockfile) { fixture_file('bundler/Gemfile-single.lock') }
    let(:result) { JSON.parse(output.string) }

    before do
      subject.execute(output: output)
    end

    specify { expect(result).to include('version' => '1.0') }
    specify { expect(result['packages']).to include('name' => 'net-hippie', 'version' => '0.3.1', 'licenses' => ['MIT']) }
  end
end
