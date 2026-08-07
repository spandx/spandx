# frozen_string_literal: true

RSpec.describe Spandx::Dotnet::NugetGateway do
  subject { described_class.new }

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

  describe '#each' do
    let(:total_pages) { 10 }

    before do
      pages = total_pages.times.map do |i|
        {
          '@id' => "https://api.nuget.org/v3/catalog0/page#{i}.json",
          'commitTimeStamp' => Time.at(i).to_datetime.iso8601
        }
      end

      stub_request(:get, 'https://api.nuget.org/v3/catalog0/index.json')
        .and_return(status: 200, body: JSON.generate({ items: pages }))

      total_pages.times do |i|
        items = {
          '@id' => "https://api.nuget.org/v3/catalog0/page#{i}.json",
          items: [{ 'nuget:id' => 'spandx', 'nuget:version' => "0.1.#{i}" }]
        }
        stub_request(:get, "https://api.nuget.org/v3/catalog0/page#{i}.json")
          .and_return(status: 200, body: JSON.generate(items))
      end
    end

    context 'when iterating through every package' do
      it 'provides each page number' do
        current = 0
        subject.each do |_id, _version, page|
          expect(page).to eql(current)
          current += 1
        end
      end

      it 'yields each id and version without an extra fetch' do
        collection = []
        subject.each do |id, version, _page|
          collection << [id, version]
        end
        expect(collection).to match_array(total_pages.times.map { |i| ['spandx', "0.1.#{i}"] })
      end
    end

    context 'when iterating through packages starting from a specific page' do
      let(:expected_pages) { 0.upto(total_pages).map(&:to_i) }

      def play
        subject.each(start_page: expected_pages.min) do |id, version, page|
          yield id, version, page
        end
      end

      it 'yields each items back' do
        called = false
        play { called = true }
        expect(called).to be(true)
      end

      it 'fetches each item starting from a specific page' do
        play { |_id, _version, page| expect(expected_pages).to include(page) }
      end
    end
  end
end
