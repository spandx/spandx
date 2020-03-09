# frozen_string_literal: true

RSpec.describe Spandx::Dotnet::NugetGateway do
  subject { described_class.new(catalogue: catalogue) }

  let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

  describe '#licenses_for' do
    context 'when the package specifies the license using an expression' do
      specify do
        VCR.use_cassette('jive-0.1.0') do
          expect(subject.licenses_for('jive', '0.1.0')).to match_array(['MIT'])
        end
      end
    end

    pending 'when the package specifies the license using a file'
    pending 'when the package specifies the license using a url'
  end

  describe "#each" do
    context "when iterating through every package" do
      let(:n) { 10 }

      before do
        pages = n.times.map do |i|
          {
            '@id' => "https://api.nuget.org/v3/catalog0/page#{i}.json",
            'commitTimeStamp' => DateTime.now.iso8601
          }
        end

        stub_request(:get, "https://api.nuget.org/v3/catalog0/index.json")
          .and_return(status: 200, body: JSON.generate({ items: pages }))

        n.times do |i|
          stub_request(:get, "https://api.nuget.org/v3/catalog0/page#{i}.json")
            .and_return(status: 200, body: JSON.generate({
              '@id' => "https://api.nuget.org/v3/catalog0/page#{i}.json",
              items: [{ '@id' => "https://api.nuget.org/v3/catalog0/data/2020.01.01.00.00.00/spandx.0.1.#{i}.json" }]
            }))

          stub_request(:get, "https://api.nuget.org/v3/catalog0/data/2020.01.01.00.00.00/spandx.0.1.#{i}.json")
            .and_return(status: 200, body: JSON.generate({ id: 'spandx', version: "0.1.#{i}", licenseExpression: 'MIT' }))
        end
      end

      it 'fetches each item' do
        collection = []
        subject.each do |item, page|
          collection << item
          expect(page).to match(/page(\d+)\.json/)
        end
        expect(collection).to match_array(n.times.map { |i| {"id"=>"spandx", "licenseExpression"=>"MIT", "version"=>"0.1.#{i}"} })
      end
    end

    context "when iterating through packages starting from a specific page" do
      it 'fetches each item starting from a specific page' do
        called = false

        VCR.use_cassette('nuget-catalogue-from-page-0') do
          subject.each(page: 0) do |item, page|
            called = true
            expect(page).to end_with('page0.json')
          end
        end

        expect(called).to be(true)
      end
    end
  end
end
