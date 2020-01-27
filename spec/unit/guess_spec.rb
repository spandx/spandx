# frozen_string_literal: true

RSpec.describe Spandx::Guess do
  subject { described_class.new(catalogue) }

  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx.json')) }

  describe '#license_for' do
    Dir["spec/fixtures/spdx/jsonld/*.jsonld"].map { |x| File.basename(x).gsub('.jsonld', '') }.each do |license|
      it "guesses the `#{license}` correctly" do
        expect(subject.license_for(license_file(license))).to eql(license)
      end
    end
  end
end
