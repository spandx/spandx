# frozen_string_literal: true

RSpec.describe Spandx::Parsers::GemfileLock do
  subject { described_class.new(catalogue: catalogue) }

  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx.json')) }

  describe '#parse' do
    context 'when parsing a Gemfile with a single dependency' do
      let(:lockfile) { fixture_file('bundler/Gemfile.lock') }

      it 'parses the lone dependency' do
        expect(subject.parse(lockfile).count).to be(1)
      end
    end
  end
end
