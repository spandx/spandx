# frozen_string_literal: true

require 'byebug'
RSpec.describe Spandx::Js::Parsers::Yarn do
  let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

  subject { described_class.new(catalogue: catalogue) }

  describe '#parse small lock file' do
    let(:lockfile) { fixture_file('js/yarn/short_yarn.lock') }

    it 'parses' do
      res = subject.parse(lockfile)
    end
  end

  describe '#parse long lock file' do
    let(:lockfile) { fixture_file('js/yarn/long_yarn.lock') }

    it 'parses' do
      res = subject.parse(lockfile)
    end
  end
end
