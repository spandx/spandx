# frozen_string_literal: true

RSpec.describe Spandx::Ruby::Parsers::GemfileLock do
  let(:described_instance) { described_class.new }

  describe '#parse' do
    def build(name, version, path)
      Spandx::Core::Dependency.new(name: name, version: version, path: path)
    end

    context 'when parsing a Gemfile that was BUNDLED_WITH 1.17.3 with a single dependency' do
      subject { described_instance.parse(path) }

      let(:path) { fixture_file('bundler/Gemfile.lock') }

      specify { expect(subject[0].meta[:dependencies]).to be_empty }
      specify { expect(subject[0].meta[:platform]).to eql('ruby') }
      specify { expect(subject[0].meta[:source]).to be_a_kind_of(Bundler::Source) }
      specify { expect(subject).to match_array([build('net-hippie', '0.2.7', path)]) }
    end

    context 'when parsing a gems.lock that was BUNDLED_WITH 2.1.2 with a single dependency' do
      subject { described_instance.parse(path) }

      let(:path) { fixture_file('bundler/gems.lock') }

      specify { expect(subject[0].meta[:dependencies]).to be_empty }
      specify { expect(subject[0].meta[:platform]).to eql('ruby') }
      specify { expect(subject[0].meta[:source]).to be_a_kind_of(Bundler::Source) }
      specify { expect(subject).to match_array([build('net-hippie', '0.2.7', path)]) }
    end

    context 'when parsing a Gemfile.lock with multiple dependencies' do
      subject { described_instance.parse(path) }

      let(:path) { Pathname.new('./Gemfile.lock') }
      let(:spandx) { subject.find { |x| x.name == 'spandx' } }

      specify do
        expect(subject).to match_array([
          build('addressable', '2.7.0', path),
          build('ast', '2.4.1', path),
          build('benchmark-ips', '2.8.2', path),
          build('benchmark-malloc', '0.2.0', path),
          build('benchmark-perf', '0.6.0', path),
          build('benchmark-trend', '0.4.0', path),
          build('bundler-audit', '0.6.1', path),
          build('byebug', '11.1.3', path),
          build('crack', '0.4.3', path),
          build('diff-lcs', '1.3', path),
          build('dotenv', '2.7.5', path),
          build('faraday', '1.0.1', path),
          build('hashdiff', '1.0.1', path),
          build('licensed', '2.11.1', path),
          build('licensee', '9.14.0', path),
          build('mini_portile2', '2.4.0', path),
          build('multipart-post', '2.1.1', path),
          build('net-hippie', '0.3.2', path),
          build('nokogiri', '1.10.9', path),
          build('octokit', '4.18.0', path),
          build('oj', '3.10.6', path),
          build('parallel', '1.19.1', path),
          build('parser', '2.7.1.3', path),
          build('parslet', '2.0.0', path),
          build('pathname-common_prefix', '0.0.1', path),
          build('public_suffix', '4.0.5', path),
          build('rainbow', '3.0.0', path),
          build('rake', '13.0.1', path),
          build('rake-compiler', '1.1.0', path),
          build('regexp_parser', '1.7.1', path),
          build('reverse_markdown', '1.4.0', path),
          build('rexml', '3.2.4', path),
          build('rspec', '3.9.0', path),
          build('rspec-benchmark', '0.6.0', path),
          build('rspec-core', '3.9.2', path),
          build('rspec-expectations', '3.9.2', path),
          build('rspec-mocks', '3.9.1', path),
          build('rspec-support', '3.9.3', path),
          build('rubocop', '0.85.1', path),
          build('rubocop-ast', '0.0.3', path),
          build('rubocop-rspec', '1.40.0', path),
          build('ruby-prof', '1.4.1', path),
          build('ruby-progressbar', '1.10.1', path),
          build('ruby-xxHash', '0.4.0.1', path),
          build('rugged', '0.99.0', path),
          build('safe_yaml', '1.0.5', path),
          build('sawyer', '0.8.2', path),
          build('spandx', Spandx::VERSION, path),
          build('terminal-table', '1.8.0', path),
          build('thor', '0.20.3', path),
          build('tomlrb', '1.3.0', path),
          build('tty-cursor', '0.7.1', path),
          build('tty-spinner', '0.9.3', path),
          build('unicode-display_width', '1.7.0', path),
          build('vcr', '6.0.0', path),
          build('webmock', '3.8.3', path),
          build('zeitwerk', '2.3.0', path),
        ])
      end

      specify { expect(spandx.meta[:platform]).to eql('ruby') }
      specify { expect(spandx.meta[:source]).to be_a_kind_of(Bundler::Source) }
    end
  end

  describe '#match?' do
    it { is_expected.to be_match(to_path('Gemfile.lock')) }
    it { is_expected.to be_match(to_path('gems.lock')) }
    it { is_expected.to be_match(to_path('./Gemfile.lock')) }
    it { is_expected.to be_match(to_path('./gems.lock')) }
    it { is_expected.to be_match(to_path('/root/Gemfile.lock')) }
    it { is_expected.to be_match(to_path('/root/gems.lock')) }
    it { is_expected.not_to be_match(to_path('sitemap.xml')) }
    it { is_expected.not_to be_match(to_path('/root/notGemfile.lock')) }
    it { is_expected.not_to be_match(to_path('/root/notgems.lock')) }
  end
end
