# frozen_string_literal: true

RSpec.describe Spandx::Ruby::Parsers::GemfileLock do
  subject { described_class.new }

  describe '#parse' do
    context 'when parsing a Gemfile with a single dependency' do
      let(:lockfile) { fixture_file('bundler/Gemfile.lock') }
      let(:because) { subject.parse(lockfile) }

      specify { expect(because.count).to be(1) }
      specify { expect(because[0].name).to eql('net-hippie') }
      specify { expect(because[0].version).to eql('0.2.7') }
      specify { expect(because[0].meta[:dependencies]).to match_array([]) }
      specify { expect(because[0].meta[:platform]).to eql('ruby') }
      specify { expect(because[0].meta[:source]).to be_a_kind_of(Bundler::Source) }
    end

    context 'when parsing a Gemfile.lock with multiple dependencies' do
      let(:lockfile) { File.expand_path('./Gemfile.lock') }

      let(:because) { subject.parse(lockfile) }
      let(:spandx) { because.find { |x| x.name == 'spandx' } }

      specify { expect(spandx.name).to eql('spandx') }
      specify { expect(spandx.version).to eql(Spandx::VERSION) }
      specify { expect(spandx.meta[:dependencies].map(&:name)).to match_array(%w[addressable bundler fastest-csv net-hippie nokogiri parslet thor zeitwerk]) }
      specify { expect(spandx.meta[:platform]).to eql('ruby') }
      specify { expect(spandx.meta[:source]).to be_a_kind_of(Bundler::Source) }
    end
  end

  specify { expect(Spandx::Rubygems::Parsers::GemfileLock).to eql(described_class) }
end
