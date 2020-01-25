# frozen_string_literal: true

RSpec.describe Spandx::Parsers::Csproj do
  subject { described_class.new(catalogue: catalogue) }

  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx.json')) }

  describe '#parse' do
    context 'when parsing a .csproj file' do
      let(:lockfile) { fixture_file('nuget/example.csproj') }

      let(:because) do
        VCR.use_cassette(File.basename(lockfile)) do
          subject.parse(lockfile)
        end
      end
      let(:jive) { because.find { |item| item.name == 'jive' } }

      specify { expect(jive.name).to eql('jive') }
      specify { expect(jive.version).to eql('0.1.0') }
      specify { expect(jive.licenses.map(&:id)).to match_array(['MIT']) }
    end

    context 'when parsing a .csproj file that has a reference to another project' do
      let(:lockfile) { fixture_file('nuget/nested/test.csproj') }

      let(:because) do
        VCR.use_cassette(File.basename(lockfile)) do
          subject.parse(lockfile)
        end
      end

      specify { expect(because.map(&:name)).to match_array(%w[jive xunit]) }
    end
  end
end
