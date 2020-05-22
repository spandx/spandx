# frozen_string_literal: true

RSpec.describe Spandx::Dotnet::Parsers::Csproj do
  subject(:described_instance) { described_class.new }

  def build(name, version, path)
    Spandx::Core::Dependency.new(name: name, version: version, path: path)
  end

  describe '#parse' do
    context 'when parsing a .csproj file' do
      subject { described_instance.parse(file) }

      let(:file) { fixture_file('nuget/example.csproj') }

      let(:jive) { subject.find { |item| item.name == 'jive' } }

      specify { expect(subject).to match_array([build('jive', '0.1.0', file)]) }
    end

    context 'when parsing a .csproj file that has a reference to another project' do
      subject { described_instance.parse(fixture_file('nuget/nested/test.csproj')) }

      specify { expect(subject.map(&:name)).to match_array(%w[jive xunit]) }
    end

    context 'when parsing `Nancy.Hosting.Self.csproj`' do
      subject { described_instance.parse(fixture_file('nuget/Nancy.Hosting.Self.csproj')) }

      specify { expect(subject.count).to be(1) }
      specify { expect(subject[0].name).to eql('System.Security.Principal.Windows') }
      specify { expect(subject[0].version).to eql('4.3.0') }
    end
  end

  describe '#match?' do
    specify { is_expected.to be_match(to_path('/root/Packages.props')) }
    specify { is_expected.to be_match(to_path('/root/simple.csproj')) }
    specify { is_expected.not_to be_match(to_path('/root/simple.sln')) }
    specify { is_expected.to be_match(to_path('C:\Documents and Settings\hello world.csproj')) }
    specify { is_expected.to be_match(to_path('C:\Documents and Settings\simple.csproj')) }
  end
end
