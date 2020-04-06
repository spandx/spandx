# frozen_string_literal: true

RSpec.describe Spandx::Js::Parsers::Npm do
  subject { described_class.new(catalogue: catalogue) }

  let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

  describe '#parse lock file' do
    let(:lockfile) { fixture_file('js/npm/package-lock.json') }
    let(:expected_dependencies) { fixture_file_content('js/npm/expected').lines.map(&:chomp) }
    let(:result) do
      VCR.use_cassette('js/npm/package-lock.json') do
        subject.parse(lockfile)
      end
    end

    specify { expect(result.map { |x| "#{x.name}@#{x.version}" }) .to match_array(expected_dependencies) }
    specify { expect(result.size).to eq(50) }
    specify { expect(result.map(&:licenses).map(&:first).map(&:id).uniq).to match_array(['MIT', 'ISC', 'BSD-3-Clause']) }
  end
end
