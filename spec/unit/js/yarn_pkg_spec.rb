# frozen_string_literal: true

RSpec.describe Spandx::Js::YarnPkg do
  subject { described_class.new }

  describe '#licenses_for' do
    context 'when fetching license data for a known package' do
      let(:dependency) { instance_double(::Spandx::Core::Dependency, name: 'babel', version: '6.23.0', meta: {}) }

      let(:result) do
        VCR.use_cassette('js/yarn/babel/6.23.0') do
          subject.licenses_for(dependency)
        end
      end

      specify { expect(result).to match_array(['MIT']) }
    end

    context 'when fetching licenses for a namespaced package' do
      let(:dependency) { instance_double(::Spandx::Core::Dependency, name: '@babel/core', version: '7.8.4', meta: {}) }

      let(:result) do
        VCR.use_cassette('js/yarn/@babel/core/7.8.4') do
          subject.licenses_for(dependency)
        end
      end

      specify { expect(result).to match_array(['MIT']) }
    end

    context 'when fetching licenses for a @types/node-10.12.9' do
      let(:dependency) { instance_double(Spandx::Core::Dependency, name: '@types/node', version: '10.12.9', meta: {}) }

      let(:result) do
        VCR.use_cassette('js/yarn/@types/node/10.12.9') do
          subject.licenses_for(dependency)
        end
      end

      specify { expect(result).to match_array(['MIT']) }
    end

    context 'when the version does not exist' do
      let(:dependency) { instance_double(Spandx::Core::Dependency, name: 'babel', version: 'invalid.23.0', meta: {}) }

      let(:result) do
        VCR.use_cassette('js/yarn/babel/invalid.23.0') do
          subject.licenses_for(dependency)
        end
      end

      specify { expect(result).to be_empty }
    end

    context 'when the name does not exist' do
      let(:dependency) { instance_double(::Spandx::Core::Dependency, name: 'invalid', version: '6.23.0', meta: {}) }
      let(:result) { subject.licenses_for(dependency) }

      before do
        stub_request(:get, 'https://registry.yarnpkg.com/invalid/6.23.0')
          .and_return(status: 404, body: { error: 'Not found' }.to_json)
      end

      specify { expect(result).to be_empty }
    end

    context 'when connecting to a custom source' do
      let(:dependency) { instance_double(::Spandx::Core::Dependency, name: 'babel', version: '6.23.0', meta: { 'resolved' => 'https://example.com' }) }
      let(:result) { subject.licenses_for(dependency) }

      before do
        stub_request(:get, 'https://example.com/babel/6.23.0')
          .and_return(status: 200, body: { versions: { '6.23.0' => { license: 'MIT' } } }.to_json)
      end

      specify { expect(result).to match_array(['MIT']) }
    end

    context 'when the endpoint returns an unexpected response' do
      let(:dependency) { instance_double(::Spandx::Core::Dependency, name: 'babel', version: '6.23.0', meta: {}) }
      let(:result) { subject.licenses_for(dependency) }

      before do
        stub_request(:get, 'https://registry.yarnpkg.com/babel/6.23.0')
          .and_return(status: 200, body: {}.to_json)
      end

      specify { expect(result).to be_empty }
    end
  end
end
