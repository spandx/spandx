# frozen_string_literal: true

RSpec.describe Spandx::Cli::Commands::Scan do
  subject { described_class.new(lockfile, options) }

  let(:output) { StringIO.new }
  let(:lockfile) { '.' }
  let(:options) { { format: 'json' } }

  before do
    stub_request(:get, Spandx::Spdx::Gateway::URL)
      .to_return(status: 200, body: IO.read(fixture_file('spdx/json/licenses.json')))
  end

  context 'when scanning a directory' do
    let(:lockfile) { fixture_file('bundler/') }
    let(:result) { JSON.parse(output.string) }

    before do
      VCR.use_cassette('scan-directory') do
        subject.execute(output: output)
      end
    end

    specify { expect(result['dependencies'].count).to be(1) }
    specify { expect(result).to include('version' => '1.0') }
    specify { expect(result['dependencies']).to match_array([{ 'name' => 'net-hippie', 'version' => '0.2.7', 'licenses' => ['MIT'] }]) }
  end

  context 'when recursively scanning a directory' do
    let(:lockfile) { fixture_file('.') }
    let(:options) { { 'recursive' => true, format: 'table' } }
    let(:result) { output.string }

    before do
      VCR.use_cassette('scan-directory-recursively') do
        subject.execute(output: output)
      end
    end

    it { expect(result).to eql(fixture_file_content('recursive.expected')) }
  end

  context 'when scanning Gemfile.lock' do
    let(:lockfile) { fixture_file('bundler/Gemfile.lock') }
    let(:result) { JSON.parse(output.string) }

    before do
      VCR.use_cassette(File.basename(lockfile)) do
        subject.execute(output: output)
      end
    end

    specify { expect(result).to include('version' => '1.0') }
    specify { expect(result['dependencies']).to include('name' => 'net-hippie', 'version' => '0.2.7', 'licenses' => ['MIT']) }
  end

  context 'when scanning gems.lock' do
    let(:lockfile) { fixture_file('bundler/gems.lock') }
    let(:result) { JSON.parse(output.string) }

    before do
      VCR.use_cassette(File.basename(lockfile)) do
        subject.execute(output: output)
      end
    end

    specify { expect(result).to include('version' => '1.0') }
    specify { expect(result['dependencies']).to include('name' => 'net-hippie', 'version' => '0.2.7', 'licenses' => ['MIT']) }
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
    specify { expect(result['dependencies']).to include('name' => 'six', 'version' => '1.13.0', 'licenses' => ['MIT']) }
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
    specify { expect(result['dependencies']).to include('name' => 'NHibernate', 'version' => '5.2.6', 'licenses' => ['LGPL-2.1-only']) }
  end
end
