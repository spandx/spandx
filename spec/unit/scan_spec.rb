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
    let(:lockfile) { fixture_file('bundler/Gemfile.lock') }
    let(:result) { JSON.parse(output.string) }

    before do
      subject.execute(output: output)
    end

    specify { expect(result).to include('version' => '1.0') }
    specify { expect(result['packages']).to include('name' => 'net-hippie', 'version' => '0.3.1', 'licenses' => ['MIT']) }
  end

  context 'when scanning gems.lock' do
    let(:lockfile) { fixture_file('bundler/gems.lock') }
    let(:result) { JSON.parse(output.string) }

    before do
      subject.execute(output: output)
    end

    specify { expect(result).to include('version' => '1.0') }
    specify { expect(result['packages']).to include('name' => 'net-hippie', 'version' => '0.3.1', 'licenses' => ['MIT']) }
  end

  context 'when scanning Pipfile.lock' do
    let(:lockfile) { fixture_file('pip/Pipfile.lock') }
    let(:result) { JSON.parse(output.string) }

    before do
      VCR.use_cassette(File.basename(lockfile)) do
        subject.execute(output: output)
      end
    end

    specify { expect(result).to include('version' => '1.0') }
    specify { expect(result['packages']).to include('name' => 'six', 'version' => '1.13.0', 'licenses' => ['MIT']) }
  end

  context 'when scanning a packages.config' do
    let(:lockfile) { fixture_file('nuget/packages.config') }
    let(:result) { JSON.parse(output.string) }

    before do
      VCR.use_cassette(File.basename(lockfile)) do
        subject.execute(output: output)
      end
    end

    specify { expect(result).to include('version' => '1.0') }
    specify { expect(result['packages']).to include('name' => 'NHibernate', 'version' => '5.2.6', 'licenses' => ['LGPL']) }
    specify { expect(result['packages']).to include('name' => 'Antlr3.Runtime', 'version' => '', 'licenses' => ['']) }
    specify { expect(result['packages']).to include('name' => 'Iesi.Collections', 'version' => '', 'licenses' => ['']) }
    specify { expect(result['packages']).to include('name' => 'Remotion.Linq', 'version' => '', 'licenses' => ['']) }
    specify { expect(result['packages']).to include('name' => 'Remotion.Linq.EagerFetching', 'version' => '', 'licenses' => ['']) }
  end
end
