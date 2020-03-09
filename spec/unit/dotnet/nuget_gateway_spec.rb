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
