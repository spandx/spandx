# frozen_string_literal: true

RSpec.describe Spandx::Js::NpmGateway do
  subject { described_class.new }

  describe '#each_package' do
    let(:names) { [] }

    context 'when the last page has fewer rows than the batch size' do
      before do
        stub_request(:get, "#{described_class::ALL_DOCS_URL}?limit=2")
          .to_return(status: 200, body: JSON.generate(rows: [{ 'id' => 'lodash' }]))

        subject.each_package(batch_size: 2) { |name| names << name }
      end

      specify { expect(names).to eql(%w[lodash]) }
    end

    context 'when the last page exactly fills the batch size' do
      before do
        stub_request(:get, "#{described_class::ALL_DOCS_URL}?limit=2")
          .to_return(status: 200, body: JSON.generate(rows: [{ 'id' => 'lodash' }, { 'id' => 'react' }]))
        stub_request(:get, "#{described_class::ALL_DOCS_URL}?limit=2&skip=1&startkey=%22react%22")
          .to_return(status: 200, body: JSON.generate(rows: []))

        subject.each_package(batch_size: 2) { |name| names << name }
      end

      specify { expect(names).to eql(%w[lodash react]) }
    end

    context 'when there is more than one page' do
      before do
        stub_request(:get, "#{described_class::ALL_DOCS_URL}?limit=2")
          .to_return(status: 200, body: JSON.generate(rows: [{ 'id' => 'lodash' }, { 'id' => 'react' }]))

        stub_request(:get, "#{described_class::ALL_DOCS_URL}?limit=2&skip=1&startkey=%22react%22")
          .to_return(status: 200, body: JSON.generate(rows: [{ 'id' => 'vue' }]))

        subject.each_package(batch_size: 2) { |name| names << name }
      end

      specify { expect(names).to eql(%w[lodash react vue]) }
    end
  end

  describe '#resolve' do
    before do
      stub_request(:get, "#{described_class::REGISTRY_URL}/lodash").to_return(
        status: 200,
        body: JSON.generate(
          versions: {
            '4.17.21' => { 'name' => 'lodash', 'version' => '4.17.21', 'license' => 'MIT' },
            '0.1.0' => { 'name' => 'lodash', 'version' => '0.1.0', 'licenses' => [{ 'type' => 'MIT' }] },
          }
        )
      )
    end

    specify do
      expect(subject.resolve(subject, 'lodash')).to match_array([
        ['lodash', '4.17.21', ['MIT']],
        ['lodash', '0.1.0', ['MIT']],
      ])
    end
  end

  describe '#metadata_for' do
    context 'when the package is reachable' do
      before do
        stub_request(:get, "#{described_class::REGISTRY_URL}/lodash")
          .to_return(status: 200, body: JSON.generate(versions: { '1.0.0' => { 'name' => 'lodash', 'version' => '1.0.0' } }))
      end

      specify { expect(subject.metadata_for('lodash')).to include('versions') }
    end

    context 'when the package is not reachable' do
      before do
        stub_request(:get, "#{described_class::REGISTRY_URL}/lodash").to_return(status: 404)
      end

      specify { expect(subject.metadata_for('lodash')).to be_empty }
    end

    context 'when the package name is scoped' do
      before do
        stub_request(:get, "#{described_class::REGISTRY_URL}/@babel%2fcore")
          .to_return(status: 200, body: JSON.generate(versions: {}))
      end

      specify { expect(subject.metadata_for('@babel/core')).to include('versions') }
    end
  end
end
