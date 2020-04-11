# frozen_string_literal: true

RSpec.describe Spandx::Java::Parsers::Maven do
  subject { described_class.new }

  describe '#parse' do
    context 'when parsing a simple-pom.xml' do
      let(:lockfile) { fixture_file('maven/simple-pom.xml') }

      let(:because) { subject.parse(lockfile) }

      specify { expect(because[0].name).to eql('junit:junit') }
      specify { expect(because[0].version).to eql('3.8.1') }
    end
  end

  describe '.matches?' do
    subject { described_class }

    specify { expect(subject.matches?('pom.xml')).to be(true) }
    specify { expect(subject.matches?('sitemap.xml')).to be(false) }
  end
end
