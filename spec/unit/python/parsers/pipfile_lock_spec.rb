# frozen_string_literal: true

RSpec.describe Spandx::Python::Parsers::PipfileLock do
  describe '#parse' do
    subject { described_class.new.parse(path) }

    let(:path) { fixture_file('pip/Pipfile.lock') }

    def build(name, version, path)
      Spandx::Core::Dependency.new(name: name, version: version, path: path)
    end

    specify { expect(subject).to match_array([build('six', '1.13.0', path)]) }
  end

  describe '#match?' do
    it { is_expected.to be_match(to_path('Pipfile.lock')) }
    it { is_expected.to be_match(to_path('./Pipfile.lock')) }
    it { is_expected.to be_match(to_path('/root/Pipfile.lock')) }
    it { is_expected.not_to be_match(to_path('sitemap.xml')) }
    it { is_expected.not_to be_match(to_path('/root/notPipfile.lock')) }
  end
end
