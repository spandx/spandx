# frozen_string_literal: true

RSpec.describe Spandx::Guess do
  subject { described_class.new(catalogue) }

  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx.json')) }

  describe '#license_for' do
    it 'guesses the license correctly' do
      catalogue.each do |license|
        expect(subject.license_for(license_file(license.id))).to eql(license.id)
      end
    end
  end
end
