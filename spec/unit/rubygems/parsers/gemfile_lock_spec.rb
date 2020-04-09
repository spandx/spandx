# frozen_string_literal: true

RSpec.describe Spandx::Ruby::Parsers::GemfileLock do
  subject { described_class.new(catalogue: catalogue) }

  let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

  describe '#parse' do
    context 'when parsing a Gemfile with a single dependency' do
      let(:lockfile) { fixture_file('bundler/Gemfile.lock') }
      let(:because) do
        VCR.use_cassette(File.basename(lockfile)) do
          subject.parse(lockfile)
        end
      end

      specify { expect(because.count).to be(1) }
      specify { expect(because[0].name).to eql('net-hippie') }
      specify { expect(because[0].version).to eql('0.2.7') }
      specify { expect(because[0].licenses.map(&:id)).to match_array(['MIT']) }
    end
  end
end
