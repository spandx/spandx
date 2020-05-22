# frozen_string_literal: true

RSpec.describe Spandx::Dotnet::Parsers::Sln do
  def build(name, version, path)
    Spandx::Core::Dependency.new(name: name, version: version, path: path)
  end

  describe '#parse' do
    context 'when parsing a sln file without any project references' do
      specify { expect(subject.parse(fixture_file('nuget/empty.sln'))).to be_empty }
    end

    context 'when parsing a sln file with a single project reference' do
      subject { described_class.new.parse(path) }

      let(:path) { fixture_file('nuget/single.sln') }
      let(:csproj_path) { path.parent.join('nested/test.csproj') }

      specify do
        expect(subject).to match_array([
          build('jive', '0.1.0', csproj_path),
          build('xunit', '2.4.0', csproj_path)
        ])
      end
    end
  end

  describe '#match?' do
    it { is_expected.to be_match(to_path('example.sln')) }
    it { is_expected.to be_match(to_path('./example.sln')) }
    it { is_expected.to be_match(to_path('/root/example.sln')) }
    it { is_expected.to be_match(to_path('C:\development\hello world.sln')) }
    it { is_expected.not_to be_match(to_path('/root/not.sln.csproj')) }
  end
end
