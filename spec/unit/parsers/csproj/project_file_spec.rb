# frozen_string_literal: true

RSpec.describe Spandx::Parsers::Csproj::ProjectFile do
  subject { described_class.new(path) }

  describe '#package_references' do
    context 'simple.csproj' do
      let(:path) { fixture_file('nuget/example.csproj') }

      specify { expect(subject.package_references.count).to be(1) }
      specify { expect(subject.package_references[0].name).to eql('jive') }
      specify { expect(subject.package_references[0].version).to eql('0.1.0') }
    end
  end
end
