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
          items: [{ '@id' => "https://api.nuget.org/v3/catalog0/data/2020.01.01.00.00.00/spandx.0.1.#{i}.json" }]
        }
        stub_request(:get, "https://api.nuget.org/v3/catalog0/page#{i}.json")
          .and_return(status: 200, body: JSON.generate(items))

        stub_request(:get, "https://api.nuget.org/v3/catalog0/data/2020.01.01.00.00.00/spandx.0.1.#{i}.json")
          .and_return(status: 200, body: JSON.generate({ id: 'spandx', version: "0.1.#{i}", licenseExpression: 'MIT' }))
      end
    end

    context 'when iterating through every package' do
      it 'provides each page number' do
        current = 0
        subject.each do |_item, page|
          expect(page).to eql(current)
          current += 1
        end
      end

      it 'fetches each item' do
        collection = []
        subject.each do |item, _page|
          collection << item
        end
        expect(collection).to match_array(total_pages.times.map { |i| { 'id' => 'spandx', 'licenseExpression' => 'MIT', 'version' => "0.1.#{i}" } })
      end
    end

    context 'when iterating through packages starting from a specific page' do
      let(:expected_pages) { 0.upto(total_pages).map(&:to_i) }

      def play
        subject.each(start_page: expected_pages.min) do |item, page|
          yield item, page
        end
      end

      it 'yields each items back' do
        called = false
        play { called = true }
        expect(called).to be(true)
      end

      it 'fetches each item starting from a specific page' do
        play { |_item, page| expect(expected_pages).to include(page) }
      end
    end
  end
end
