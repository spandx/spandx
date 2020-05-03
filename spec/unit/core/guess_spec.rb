# frozen_string_literal: true

RSpec.describe Spandx::Core::Guess do
  subject { described_class.new(catalogue) }

  let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }
  let(:active_licenses) { catalogue.find_all { |x| !x.deprecated_license_id? } }

  describe '#license_for' do
    pending 'detects each license in the SPDX catalogue' do
      active_licenses.each do |license|
        expect(subject.license_for(license.content.raw)).to eql(license)
      end
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
          expect(subject.license_for(license.content.raw)).to eql(license)
        end
      end
    end

    pending 'does not contain any duplicate names' do
      items = Hash.new { |hash, key| hash[key] = 0 }
      active_licenses.each { |license| items[license.name] += 1 }
      expect(items.find_all { |_x, y| y > 1 }).to be_empty
    end

    context 'when guessing the spandx license' do
      let!(:content) { IO.read('LICENSE.txt') }

      specify { expect(subject.license_for(content)&.id).to eql('MIT') }
    end

    pending { expect(subject.license_for('(0BSD OR MIT)')&.id).to eql('0BSD') }
    pending { expect(subject.license_for('(BSD-2-Clause OR MIT OR Apache-2.0)')&.id).to eql('BSD-2-Clause') }
    pending { expect(subject.license_for('(BSD-3-Clause OR GPL-2.0)')&.id).to eql('BSD-3-Clause') }
    pending { expect(subject.license_for('(MIT AND CC-BY-3.0)')&.id).to eql('(MIT AND CC-BY-3.0)') }
    pending { expect(subject.license_for('(MIT AND Zlib)')&.id).to eql(%w[MIT Zlib]) }
    pending { expect(subject.license_for('(MIT OR Apache-2.0)')&.id).to eql('MIT') }
    pending { expect(subject.license_for('(MIT OR CC0-1.0)')&.id).to eql('MIT') }
    pending { expect(subject.license_for('(MIT OR GPL-3.0)')&.id).to eql('MIT') }
    pending { expect(subject.license_for('(WTFPL OR MIT)')&.id).to eql('WTFPL') }
    pending { expect(subject.license_for('BSD-3-Clause OR MIT')&.id).to eql('BSD-3-Clause') }
    pending { expect(subject.license_for('BSD-like')&.id).to eql('MIT') }
    pending { expect(subject.license_for('MIT or GPLv3')&.id).to eql('MIT') }
    pending { expect(subject.license_for('MIT/X11')&.id).to eql('X11') }
    specify { expect(subject.license_for('Apache 2.0')&.id).to eql('Apache-2.0') }
    specify { expect(subject.license_for('Common Public License Version 1.0')&.id).to eql('CPL-1.0') }
  end
end
