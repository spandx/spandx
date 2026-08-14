# frozen_string_literal: true

RSpec.describe Spandx::Dotnet::NugetGateway do
  subject { described_class.new(catalogue:) }

  let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

  describe '#licenses_for' do
    context 'when the package specifies the license using an expression' do
      let(:dependency) { instance_double(::Spandx::Core::Dependency, name: 'jive', version: '0.1.0') }

      specify do
        VCR.use_cassette('jive-0.1.0') do
          expect(subject.licenses_for(dependency)).to match_array(['MIT'])
        end
      end
    end

    pending 'when the package specifies the license using a file'
    pending 'when the package specifies the license using a url'
  end

  describe '#licenses' do
    context 'when the package id has mixed case' do
      before do
        stub_request(:get, 'https://api.nuget.org/v3-flatcontainer/newtonsoft.json/13.0.3/newtonsoft.json.nuspec').to_return(
          status: 200,
          body: '<package><metadata><license type="expression">MIT</license></metadata></package>'
        )
      end

      specify { expect(subject.licenses('Newtonsoft.Json', '13.0.3')).to match_array(['MIT']) }
    end
  end

  describe '#licenses_from' do
    def licenses_for(entry)
      subject.licenses_from(entry)
    end

    it 'prefers the SPDX expression when present' do
      expect(licenses_for('licenseExpression' => 'MIT', 'licenseUrl' => 'https://example.com/x')).to eql(['MIT'])
    end

    it 'keeps a composite expression intact' do
      expect(licenses_for('licenseExpression' => 'MIT OR Apache-2.0')).to eql(['MIT OR Apache-2.0'])
    end

    it 'reads the expression out of a licenses.nuget.org url' do
      expect(licenses_for('licenseUrl' => 'https://licenses.nuget.org/MIT')).to eql(['MIT'])
    end

    it 'unescapes a composite expression in a licenses.nuget.org url' do
      expect(licenses_for('licenseUrl' => 'https://licenses.nuget.org/(MIT%20OR%20Apache-2.0)')).to eql(['(MIT OR Apache-2.0)'])
    end

    it 'maps a well-known license url to its SPDX id' do
      expect(licenses_for('licenseUrl' => 'http://www.apache.org/licenses/LICENSE-2.0')).to eql(['Apache-2.0'])
    end

    it 'stores an unrecognised url verbatim rather than fetching it' do
      url = 'https://raw.githubusercontent.com/nhibernate/nhibernate-core/master/LICENSE.txt'
      expect(licenses_for('licenseUrl' => url)).to eql([url])
    end

    it 'returns nothing when the package declares no license' do
      expect(licenses_for('licenseExpression' => '', 'licenseUrl' => '')).to be_empty
    end
  end

  describe '#versions_for' do
    let(:registration) { 'https://api.nuget.org/v3/registration5-gz-semver2/spandx/index.json' }

    def entry(version, expression)
      { 'catalogEntry' => { 'id' => 'Spandx', 'version' => version, 'licenseExpression' => expression } }
    end

    context 'when the registration pages are inlined' do
      before do
        stub_request(:get, registration).to_return(
          status: 200,
          body: JSON.generate(items: [{ 'items' => [entry('1.0.0', 'MIT'), entry('2.0.0', 'Apache-2.0')] }])
        )
      end

      specify { expect(subject.versions_for('Spandx').map { |x| x['version'] }).to eql(['1.0.0', '2.0.0']) }
    end

    context 'when a registration page has to be fetched separately' do
      before do
        page = 'https://api.nuget.org/v3/registration5-gz-semver2/spandx/page/1.0.0/2.0.0.json'
        stub_request(:get, registration).to_return(status: 200, body: JSON.generate(items: [{ '@id' => page }]))
        stub_request(:get, page).to_return(status: 200, body: JSON.generate(items: [entry('1.0.0', 'MIT')]))
      end

      specify { expect(subject.versions_for('Spandx').map { |x| x['version'] }).to eql(['1.0.0']) }
    end

    context 'when the package id has mixed case' do
      before do
        stub_request(:get, registration).to_return(status: 200, body: JSON.generate(items: []))
      end

      specify { expect(subject.versions_for('Spandx')).to be_empty }
    end
  end

  describe '#each' do
    let(:total_pages) { 10 }

    before do
      pages = total_pages.times.map do |i|
        { '@id' => "https://api.nuget.org/v3/catalog0/page#{i}.json", 'commitTimeStamp' => Time.at(i).to_datetime.iso8601 }
      end
      stub_request(:get, 'https://api.nuget.org/v3/catalog0/index.json')
        .and_return(status: 200, body: JSON.generate({ items: pages }))

      total_pages.times do |i|
        items = [
          { 'nuget:id' => 'Spandx', 'nuget:version' => "0.1.#{i}" },
          { 'nuget:id' => 'spandx', 'nuget:version' => "0.2.#{i}" },
          { 'nuget:id' => "Only.On.Page#{i}", 'nuget:version' => '1.0.0' },
        ]
        stub_request(:get, "https://api.nuget.org/v3/catalog0/page#{i}.json")
          .and_return(status: 200, body: JSON.generate({ '@id' => "https://api.nuget.org/v3/catalog0/page#{i}.json", items: }))
      end
    end

    it 'yields each package id exactly once, case-insensitively' do
      ids = []
      subject.each { |id| ids << id }

      expect(ids.count { |id| id.casecmp('spandx').zero? }).to be(1)
    end

    it 'yields the id from every page' do
      ids = []
      subject.each { |id| ids << id }

      expect(ids).to include(*total_pages.times.map { |i| "Only.On.Page#{i}" })
    end

    it 'does not yield versions' do
      expect { |b| subject.each(&b) }.to yield_successive_args(*Array.new(total_pages + 1, String))
    end

    context 'when starting from a specific page' do
      it 'skips earlier pages' do
        ids = []
        subject.each(start_page: total_pages - 1) { |id| ids << id }

        expect(ids).to contain_exactly('Spandx', "Only.On.Page#{total_pages - 1}")
      end
    end
  end

  describe '#resolve' do
    before do
      stub_request(:get, 'https://api.nuget.org/v3/registration5-gz-semver2/spandx/index.json').to_return(
        status: 200,
        body: JSON.generate(
          items: [{ 'items' => [
            { 'catalogEntry' => { 'id' => 'Spandx', 'version' => '1.0.0', 'licenseExpression' => 'MIT' } },
            { 'catalogEntry' => { 'id' => 'Spandx', 'version' => '2.0.0', 'licenseUrl' => 'https://licenses.nuget.org/Apache-2.0' } },
          ] }]
        )
      )
    end

    it 'returns one record per version' do
      expect(subject.resolve(subject, 'Spandx')).to eql(
        [['Spandx', '1.0.0', ['MIT']], ['Spandx', '2.0.0', ['Apache-2.0']]]
      )
    end
  end

  # `resolve` runs on a worker, not on the gateway that dispatched it. A worker
  # built without the catalogue resolves every url to itself, which is how
  # 20,836 opensource.org urls reached the index verbatim.
  describe '#worker' do
    let(:worker) { subject.send(:worker) }

    it 'carries the catalogue' do
      expect(worker.licenses_from('licenseUrl' => 'https://opensource.org/licenses/MIT')).to eql(['MIT'])
    end

    it 'carries the concurrency' do
      gateway = described_class.new(catalogue:, concurrency: 3)

      expect(gateway.send(:worker).instance_variable_get(:@concurrency)).to be(3)
    end
  end
end
