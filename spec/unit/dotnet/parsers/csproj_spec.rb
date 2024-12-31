# frozen_string_literal: true

RSpec.describe Spandx::Dotnet::Parsers::Csproj do
  subject(:described_instance) { described_class.new }

  def build(name, version, path)
    Spandx::Core::Dependency.new(name:, version:, path:)
  end

  describe '#parse' do
    context 'when parsing a .csproj file' do
      subject { described_instance.parse(file) }

      let(:file) { fixture_file('nuget/example.csproj') }

      let(:jive) { subject.find { |item| item.name == 'jive' } }

      it { is_expected.to match_array([build('jive', '0.1.0', file)]) }
    end

    context 'when parsing a .csproj file that has a reference to another project' do
      subject { described_instance.parse(fixture_file('nuget/nested/test.csproj')) }

      it { expect(subject.map(&:name)).to match_array(%w[jive xunit]) }
    end

    context 'when parsing `Nancy.Hosting.Self.csproj`' do
      subject { described_instance.parse(fixture_file('nuget/Nancy.Hosting.Self.csproj')) }

      it { expect(subject.count).to be(1) }
      it { expect(subject[0].name).to eql('System.Security.Principal.Windows') }
      it { expect(subject[0].version).to eql('4.3.0') }
    end
  end

  describe '#match?' do
    it { is_expected.to be_match(to_path('/root/Packages.props')) }
    it { is_expected.to be_match(to_path('/root/simple.csproj')) }
    it { is_expected.not_to be_match(to_path('/root/simple.sln')) }
    it { is_expected.to be_match(to_path('C:\Documents and Settings\hello world.csproj')) }
    it { is_expected.to be_match(to_path('C:\Documents and Settings\simple.csproj')) }
  end
end
