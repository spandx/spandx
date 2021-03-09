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
        expect(subject.map(&:name)).to match_array([
          'addressable',
          'ast',
          'benchmark-ips',
          'benchmark-malloc',
          'benchmark-perf',
          'benchmark-trend',
          'bundler-audit',
          'byebug',
          'crack',
          'diff-lcs',
          'dotenv',
          'faraday',
          'faraday-net_http',
          'hashdiff',
          'licensed',
          'licensee',
          'mini_portile2',
          'multipart-post',
          'net-hippie',
          'nokogiri',
          'octokit',
          'oj',
          'parallel',
          'parser',
          'parslet',
          'pathname-common_prefix',
          'public_suffix',
          'racc',
          'rainbow',
          'rake',
          'rake-compiler',
          'rbtree3',
          'regexp_parser',
          'reverse_markdown',
          'rexml',
          'rspec',
          'rspec-benchmark',
          'rspec-core',
          'rspec-expectations',
          'rspec-mocks',
          'rspec-support',
          'rubocop',
          'rubocop-ast',
          'rubocop-rspec',
          'ruby-prof',
          'ruby-progressbar',
          'ruby-xxHash',
          'ruby2_keywords',
          'rugged',
          'sawyer',
          'set',
          'sorted_set',
          'spandx',
          'terminal-table',
          'thor',
          'tomlrb',
          'tty-cursor',
          'tty-spinner',
          'unicode-display_width',
          'vcr',
          'webmock',
          'zeitwerk',
        ])
      end

      specify { expect(subject.map(&:path).uniq).to match_array([path.expand_path]) }
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
