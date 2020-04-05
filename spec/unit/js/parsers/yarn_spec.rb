# frozen_string_literal: true

RSpec.describe Spandx::Js::Parsers::Yarn do
  subject { described_class.new(catalogue: catalogue) }

  let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

  describe '#parse small lock file' do
    let(:lockfile) { fixture_file('js/yarn/short_yarn.lock') }
    let(:result) { subject.parse(lockfile) }

    specify { expect(result.size).to eq(2) }
    specify { expect(result.first.name).to eq('babel') }
    specify { expect(result.first.version).to eq('6.23.0') }
    pending { expect(result.first.licenses).to match_array(['MIT']) }
  end

  describe '#invalid lock file' do
    let(:lockfile) { fixture_file('js/yarn/invalid_yarn.lock') }

    specify { expect(subject.parse(lockfile)).to be_empty }
  end

  describe '#parse long lock file' do
    let(:lockfile) { fixture_file('js/yarn/long_yarn.lock') }
    let(:result) { subject.parse(lockfile).to_a }
    let(:expected_dependencies) { fixture_file_content('js/yarn/lol').lines.map(&:chomp) }

    specify { expect(result.map { |x| "#{x.name}@#{x.version}" }) .to match_array(expected_dependencies) }
    specify { expect(result.size).to eq(53) }
  end
end
