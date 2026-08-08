# frozen_string_literal: true

RSpec.describe Spandx::Core::Guess do
  subject { described_class.new(catalogue) }

  let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }
  let(:active_licenses) { catalogue.find_all { |x| !x.deprecated_license_id? } }

  describe '#license_for' do
    context 'when given a license url' do
      let(:known_url) { 'https://licenses.nuget.org/MIT' }

      it 'resolves a well-known url' do
        expect(subject.license_for(known_url).id).to eql('MIT')
      end

      it 'does not hit the network for a well-known url' do
        allow(Spandx.http).to receive(:get)

        subject.license_for(known_url)

        expect(Spandx.http).not_to have_received(:get)
      end

      it 'downloads an unmapped url and matches its body' do
        url = 'https://example.com/LICENSE.txt'
        stub_request(:get, url).to_return(status: 200, body: IO.read('LICENSE.txt'))

        expect(subject.license_for(url).id).to eql('MIT')
      end

      it 'prefers a url it can map over the accompanying name' do
        expect(subject.license_for(name: 'Custom Vendor Terms', url: known_url).id).to eql('MIT')
      end
    end

    it 'reads each SPDX license text at most once across calls' do
      reads = Hash.new(0)
      allow(Spandx.git[:spdx]).to receive(:read) { |path| reads[path] += 1 and nil }

      2.times { subject.license_for("no such license #{SecureRandom.uuid}") }

      expect(reads.values.max).to be(1)
    end

    context 'when detecting a license by id' do
      specify do
        active_licenses.each do |license|
          expect(subject.license_for(license.id)).to eql(license)
        end
      end
    end

    context 'when detecting a license by name' do
      pending do
        active_licenses.each do |license|
          expect(subject.license_for(license.name)).to eql(license)
        end
      end
    end

    context 'when detecting a license by text' do
      pending do
        active_licenses.each do |license|
          content = Spandx.git[:spdx].read("text/#{license.id}.txt")
          expect(subject.license_for(content)).to eql(license)
        end
      end
    end

    specify 'does not contain any duplicate names' do
      items = Hash.new { |hash, key| hash[key] = 0 }
      active_licenses.each { |license| items[license.name] += 1 }
      expect(items.find_all { |_x, y| y > 1 }).to be_empty
    end

    context 'when guessing the spandx license' do
      let!(:content) { IO.read('LICENSE.txt') }

      specify { expect(subject.license_for(content)&.id).to eql('MIT') }
    end

    specify { expect(subject.license_for(%w[MIT 0BSD]).id).to eql('MIT AND 0BSD') }
    specify { expect(subject.license_for('(0BSD OR MIT)')&.id).to eql('0BSD OR MIT') }
    specify { expect(subject.license_for('(BSD-2-Clause OR MIT OR Apache-2.0)')&.id).to eql('BSD-2-Clause OR MIT OR Apache-2.0') }
    specify { expect(subject.license_for('(BSD-3-Clause OR GPL-2.0)')&.id).to eql('BSD-3-Clause OR GPL-2.0') }
    specify { expect(subject.license_for('(MIT AND CC-BY-3.0)')&.id).to eql('MIT AND CC-BY-3.0') }
    specify { expect(subject.license_for('(MIT AND Zlib)')&.id).to eql('MIT AND Zlib') }
    specify { expect(subject.license_for('(MIT OR Apache-2.0)')&.id).to eql('MIT OR Apache-2.0') }
    specify { expect(subject.license_for('(MIT OR CC0-1.0)')&.id).to eql('MIT OR CC0-1.0') }
    specify { expect(subject.license_for('(MIT OR GPL-3.0)')&.id).to eql('MIT OR GPL-3.0') }
    specify { expect(subject.license_for('(WTFPL OR MIT)')&.id).to eql('WTFPL OR MIT') }
    specify { expect(subject.license_for('Apache 2.0')&.id).to eql('Apache-2.0') }
    specify { expect(subject.license_for('BSD-3-Clause OR MIT')&.id).to eql('BSD-3-Clause OR MIT') }
    specify { expect(subject.license_for('BSD-like')&.id).to eql('Nonstandard') }
    specify { expect(subject.license_for('Common Public License Version 1.0')&.id).to eql('CPL-1.0') }
    specify { expect(subject.license_for('MIT or GPLv3')&.id).to eql('MIT OR Nonstandard') }
    pending { expect(subject.license_for('MIT/X11')&.id).to eql('X11') }
  end
end
