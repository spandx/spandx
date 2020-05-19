# frozen_string_literal: true

RSpec.describe Spandx::Python::Source do
  describe '#lookup' do
    context 'when fetching metadata for a known package from https://pypi.org' do
      subject { described_class.default }

      let(:result) do
        VCR.use_cassette('pypi/pytest-5.4.1') do
          subject.lookup('pytest', '5.4.1')
        end
      end

      specify { expect(result).not_to be_nil }
      specify { expect(result['info']).not_to be_nil }
      specify { expect(result['info']['name']).to eql('pytest') }
      specify { expect(result['info']['version']).to eql('5.4.1') }
    end

    context 'when fetching metadata for a known package from https://test.pypi.org' do
      subject { described_class.new({ 'name' => 'pypi', 'url' => 'https://test.pypi.org/simple', 'verify_ssl' => true }) }

      let(:result) do
        VCR.use_cassette('test.pypi/pip-18.1') do
          subject.lookup('pip', '18.1')
        end
      end

      specify { expect(result).not_to be_nil }
      specify { expect(result['info']).not_to be_nil }
      specify { expect(result['info']['name']).to eql('pip') }
      specify { expect(result['info']['version']).to eql('18.1') }
    end
  end

  describe '.sources_from' do
    context 'when the source is invalid' do
      subject { described_class.sources_from(json) }

      let(:json) do
        {
          '_meta' => {
            'sources' => [
              { name: 'pypi', url: '<%= @index_url %>', 'verify_ssl' => true }
            ]
          }
        }
      end

      it 'returns the default source' do
        expect(subject).to match_array([described_class.default])
      end
    end
  end
end
