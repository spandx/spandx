# frozen_string_literal: true

RSpec.describe Spandx::Dotnet::Parsers::Sln do
  subject { described_class.new }

  describe '#parse' do
    context 'when parsing a sln file without any project references' do
      let(:sln) { fixture_file('nuget/empty.sln') }

      specify { expect(subject.parse(sln)).to be_empty }
    end

    context 'when parsing a sln file with a single project reference' do
      let(:sln) { fixture_file('nuget/single.sln') }
      let(:because) { subject.parse(sln) }

      specify { expect(because.map(&:name)).to match_array(%w[jive xunit]) }
    end
  end

  describe '.matches?' do
    subject { described_class }

    specify { expect(subject.matches?('/root/example.sln')).to be(true) }
    specify { expect(subject.matches?('C:\development\hello world.sln')).to be(true) }
  end
end
