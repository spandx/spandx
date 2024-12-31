# frozen_string_literal: true

RSpec.describe Spandx::Php::Parsers::Composer do
  def build(name, version, path)
    Spandx::Core::Dependency.new(name:, version:, path:)
  end

  describe '#parse' do
    subject { described_class.new.parse(path) }

    let(:path) { fixture_file('composer/composer.lock') }

    specify do
      expect(subject).to match_array([
        build('doctrine/instantiator', '1.3.0', path),
        build('hamcrest/hamcrest-php', 'v2.0.0', path),
        build('mockery/mockery', '1.3.1', path),
        build('phpdocumentor/reflection-common', '2.0.0', path),
        build('phpdocumentor/type-resolver', '1.0.1', path),
        build('symfony/polyfill-ctype', 'v1.14.0', path),
        build('webmozart/assert', '1.7.0', path),
      ])
    end
  end

  describe '#match?' do
    it { is_expected.to be_match(to_path('composer.lock')) }
    it { is_expected.to be_match(to_path('./composer.lock')) }
    it { is_expected.to be_match(to_path('/root/composer.lock')) }
    it { is_expected.not_to be_match(to_path('sitemap.xml')) }
    it { is_expected.not_to be_match(to_path('/root/notcomposer.lock')) }
  end
end
