# frozen_string_literal: true

RSpec.describe Spandx::Js::YarnPkg do
  subject { described_class.new(source: source) }

  let(:source) { described_class::DEFAULT_SOURCE }

  describe '#licenses_for' do
    context 'when fetching license data for a known package' do
      let(:result) do
        VCR.use_cassette('js/yarn/babel/6.23.0') do
          subject.licenses_for('babel', '6.23.0')
        end
      end

      specify { expect(result).to match_array(['MIT']) }
    end

    context 'when fetching licenses for a namespaced package' do
      let(:result) do
        VCR.use_cassette('js/yarn/@babel/core/7.8.4') do
          subject.licenses_for('@babel/core', '7.8.4')
        end
      end

      specify { expect(result).to match_array(['MIT']) }
    end

    context 'when fetching licenses for a @types/node-10.12.9' do
      let(:result) do
        VCR.use_cassette('js/yarn/@types/node/10.12.9') do
          subject.licenses_for('@types/node', '10.12.9')
        end
      end

      specify { expect(result).to match_array(['MIT']) }
    end

    context 'when the version does not exist' do
      let(:result) do
        VCR.use_cassette('js/yarn/babel/invalid.23.0') do
          subject.licenses_for('babel', 'invalid.23.0')
        end
      end

      specify { expect(result).to be_empty }
    end

    context 'when the name does not exist' do
      let(:result) { subject.licenses_for('invalid', '6.23.0') }

      before do
        stub_request(:get, 'https://registry.yarnpkg.com/invalid/6.23.0')
          .and_return(status: 404, body: { error: 'Not found' }.to_json)
      end

      specify { expect(result).to be_empty }
    end

    context 'when connecting to a custom source' do
      let(:source) { 'https://example.com' }
      let(:result) { subject.licenses_for('babel', '6.23.0') }

      before do
        stub_request(:get, 'https://example.com/babel/6.23.0')
          .and_return(status: 200, body: { versions: { '6.23.0' => { license: 'MIT' } } }.to_json)
      end

      specify { expect(result).to match_array(['MIT']) }
    end

    context 'when the endpoint returns an unexpected response' do
      let(:result) { subject.licenses_for('babel', '6.23.0') }

      before do
        stub_request(:get, 'https://registry.yarnpkg.com/babel/6.23.0')
          .and_return(status: 200, body: {}.to_json)
      end

      specify { expect(result).to be_empty }
    end
  end
end
