# frozen_string_literal: true

RSpec.describe Spandx::Spdx::Catalogue do
  subject { described_class.new(catalogue_hash) }

  let(:spdx_file) { fixture_file('spdx/json/licenses.json') }
  let(:catalogue_hash) { JSON.parse(IO.read(spdx_file), symbolize_names: true) }

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
    let(:licenses) { catalogue_hash[:licenses] }

    it { expect(subject.count).to eql(licenses.count) }
    it { expect(subject.map(&:id)).to match_array(licenses.map { |x| x[:licenseId] }) }
    it { expect(subject.map(&:name)).to match_array(licenses.map { |x| x[:name] }) }

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
      let(:gateway) { instance_double(Spandx::Spdx::Gateway, fetch: catalogue) }
      let(:catalogue) { { licenses: [{ licenseId: 'example' }] } }

      before do
        allow(Spandx::Spdx::Gateway).to receive(:new).and_return(gateway)
      end

      it { expect(subject.count).to be(1) }
    end
  end

  describe '.from_file' do
    subject { described_class.from_file(spdx_file) }

    it { expect(subject.count).to eql(catalogue_hash[:licenses].count) }
  end

  describe '.from_git' do
    subject { described_class.from_git }

    it { expect(subject.count).to be > 400 }
  end
end
