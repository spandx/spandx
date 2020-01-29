# frozen_string_literal: true

RSpec.describe Spandx::Parsers::Sln do
  subject { described_class.new(catalogue: catalogue) }

  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

  describe '#parse' do
    context 'when parsing a sln file without any project references' do
      let(:sln) { fixture_file('nuget/empty.sln') }

      it 'returns an empty list of dependencies' do
        expect(subject.parse(sln)).to be_empty
      end
    end

    context 'when parsing a sln file with a single project reference' do
      let(:sln) { fixture_file('nuget/single.sln') }

      let(:because) do
        VCR.use_cassette(File.basename(sln)) do
          subject.parse(sln)
        end
      end

      specify { expect(because.map(&:name)).to match_array(%w[jive xunit]) }
    end
  end

  describe '.matches?' do
    subject { described_class }

    specify { expect(subject.matches?('/root/example.sln')).to be(true) }
    specify { expect(subject.matches?('C:\development\hello world.sln')).to be(true) }
  end
end
