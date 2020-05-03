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
      specify { expect(subject.license_for(content, algorithm: :dice_coefficient)&.id).to eql('MIT') }
      specify { expect(subject.license_for(content, algorithm: :levenshtein)&.id).to eql('MIT') }
      specify { expect(subject.license_for(content, algorithm: :jaro_winkler)&.id).to eql('MIT') }

      %i[dice_coefficient levenshtein jaro_winkler].each do |algorithm|
        pending algorithm do
          expect do
            subject.license_for(content, algorithm: algorithm)
          end.to perform_under(0.01).sample(10)
        end
      end
    end
  end
end
