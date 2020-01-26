# frozen_string_literal: true

RSpec.describe Spandx::Guess do
  subject { described_class.new(catalogue) }

  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx.json')) }

  describe '#license_for' do
    let(:gpl_content) { license_file(spdx_id) }
    let(:gpl) { catalogue[spdx_id] }
    let(:spdx_id) { 'GPL-3.0' }

    it 'guesses the license correctly' do
      expect(subject.license_for(gpl_content)).to eql(spdx_id)
    end
  end
end
