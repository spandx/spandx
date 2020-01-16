# frozen_string_literal: true

RSpec.describe Spandx::Catalogue do
  subject { described_class.new(catalogue_hash) }

  let(:spdx_file) { File.join('spec', 'fixtures', 'spdx.json') }
  let(:spdx_json) { IO.read(spdx_file) }
  let(:catalogue_hash) { JSON.parse(spdx_json, symbolize_names: true) }

  describe '#version' do
    let(:version) { SecureRandom.uuid }

    it { expect(described_class.new(licenseListVersion: version).version).to eql(version) }
  end

  describe '#[]' do
    context 'when fetcing a license by a known id' do
      let(:result) { subject['MIT'] }

      it { expect(result.id).to eql('MIT') }
      it { expect(result.name).to eql('MIT License') }
    end

    context 'when the id is not known' do
      it { expect(subject['unknown']).to be_nil }
    end
  end

  describe '#each' do
    it { expect(subject.count).to eql(catalogue_hash[:licenses].count) }
    it { expect(subject.map(&:id)).to match_array(catalogue_hash[:licenses].map { |x| x[:licenseId] }) }
    it { expect(subject.map(&:name)).to match_array(catalogue_hash[:licenses].map { |x| x[:name] }) }

    context 'when some of the licenses are missing an identifier' do
      let(:catalogue_hash) do
        {
          licenseListVersion: '3.6',
          licenses: [
            { licenseId: nil, name: 'nil' },
            { licenseId: '', name: 'blank' },
            { licenseId: 'valid', name: 'valid' }
          ]
        }
      end

      it { expect(subject.count).to eq(1) }
      it { expect(subject.map(&:id)).to contain_exactly('valid') }
    end

    context 'when the schema of each license changes' do
      let(:catalogue_hash) do
        {
          licenseListVersion: '3.6',
          licenses: [
            {
              "license-ID": 'MIT',
              name: 'MIT License'
            }
          ]
        }
      end

      it { expect(subject.count).to be_zero }
    end

    context 'when the schema of the catalogue changes' do
      let(:catalogue_hash) { { SecureRandom.uuid.to_sym => [{ id: 'MIT', name: 'MIT License' }] } }

      it { expect(subject.count).to be_zero }
    end
  end

  describe '.latest' do
    subject { described_class.latest }

    context 'when the licenses.json endpoint is healthy' do
      let(:gateway) { instance_double(Spandx::CatalogueGateway, fetch: catalogue) }
      let(:catalogue) { instance_double(described_class) }

      before do
        allow(Spandx::CatalogueGateway).to receive(:new).and_return(gateway)
      end

      it { expect(subject).to be(catalogue) }
    end
  end

  describe '.from_file' do
    subject { described_class.from_file(spdx_file) }

    it { expect(subject.count).to eql(catalogue_hash[:licenses].count) }
  end
end
