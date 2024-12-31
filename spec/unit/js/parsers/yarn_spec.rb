# frozen_string_literal: true

RSpec.describe Spandx::Js::Parsers::Yarn do
  describe '#parse small lock file' do
    let(:result) { subject.parse(fixture_file('js/yarn/short_yarn.lock')) }

    specify { expect(result.size).to eq(2) }
    specify { expect(result.first.name).to eq('babel') }
    specify { expect(result.first.version).to eq('6.23.0') }
  end

  describe '#invalid lock file' do
    specify { expect(subject.parse(fixture_file('js/yarn/invalid_yarn.lock'))).to be_empty }
  end

  describe '#parse long lock file' do
    let(:expected_dependencies) { fixture_file_content('js/yarn/long_yarn.lock.expected').lines.map(&:chomp) }
    let(:result) { subject.parse(fixture_file('js/yarn/long_yarn.lock')) }

    specify { expect(result.map { |x| "#{x.name}@#{x.version}" }).to match_array(expected_dependencies) }
  end

  describe '#match?' do
    it { is_expected.to be_match(to_path('yarn.lock')) }
    it { is_expected.to be_match(to_path('./yarn.lock')) }
    it { is_expected.to be_match(to_path('/root/yarn.lock')) }
    it { is_expected.not_to be_match(to_path('sitemap.xml')) }
    it { is_expected.not_to be_match(to_path('/root/notyarn.lock')) }
  end
end
