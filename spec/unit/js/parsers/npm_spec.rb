# frozen_string_literal: true

RSpec.describe Spandx::Js::Parsers::Npm do
  describe '#parse' do
    subject { described_class.new.parse(fixture_file('js/npm/package-lock.json')) }

    let(:expected_dependencies) { fixture_file_content('js/npm/expected').lines.map(&:chomp) }

    specify { expect(subject.map { |x| "#{x.name}@#{x.version}" }).to match_array(expected_dependencies) }
  end

  describe '#match?' do
    it { is_expected.to be_match(to_path('package-lock.json')) }
    it { is_expected.to be_match(to_path('./package-lock.json')) }
    it { is_expected.to be_match(to_path('/root/package-lock.json')) }
    it { is_expected.not_to be_match(to_path('sitemap.xml')) }
    it { is_expected.not_to be_match(to_path('/root/notpackage-lock.json')) }
  end
end
