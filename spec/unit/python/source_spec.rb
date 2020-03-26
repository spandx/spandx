# frozen_string_literal: true

RSpec.describe Spandx::Python::Source do
  context "when fetching metadata for a known package from https://pypi.org" do
    subject { described_class.default }

    it 'fetches the correct data' do
      VCR.use_cassette('pypi/pytest-5.4.1') do
        result = subject.lookup('pytest', '5.4.1')

        expect(result).not_to be_nil
        expect(result['info']).not_to be_nil
        expect(result['info']['name']).to eql('pytest')
        expect(result['info']['version']).to eql('5.4.1')
      end
    end
  end
end
