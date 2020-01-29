# frozen_string_literal: true

RSpec.describe Spandx::Parsers::Maven do
  subject { described_class.new(catalogue: catalogue) }

  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx.json')) }

  describe '#parse' do
    context 'simple pom.xml' do
      let(:lockfile) { fixture_file('maven/simple-pom.xml') }

      let(:because) do
        VCR.use_cassette(File.basename(lockfile)) do
          subject.parse(lockfile)
        end
      end

      specify { expect(because[0].name).to eql('junit') }
      specify { expect(because[0].version).to eql('3.8.1') }
      pending { expect(because[0].licenses.map(&:id)).to match_array(['CPAL 1.0', 'CPL 1.0']) }
    end
  end

  describe '.matches?' do
    subject { described_class }

    specify { expect(subject.matches?('pom.xml')).to be(true) }
    specify { expect(subject.matches?('sitemap.xml')).to be(false) }
  end
end
