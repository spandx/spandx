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
    end
  end
end
