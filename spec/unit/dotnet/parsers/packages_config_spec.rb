# frozen_string_literal: true

RSpec.describe Spandx::Dotnet::Parsers::PackagesConfig do
  let(:described_instance) { described_class.new }

  describe '#parse' do
    context 'when parsing a Gemfile with a single dependency' do
      subject { described_instance.parse(fixture_file('nuget/packages.config')) }

      let(:nhibernate) { subject.find { |item| item.name == 'NHibernate' } }

      specify { expect(nhibernate.name).to eql('NHibernate') }
      specify { expect(nhibernate.version).to eql('5.2.6') }
      pending { expect(subject.map(&:name)).to match_array(['Antlr3.Runtime', 'Iesi.Collections', 'NHibernate', 'Remotion.Linq', 'Remotion.Linq.EagerFetching']) }
    end
  end

  describe '#match?' do
    it { is_expected.not_to be_match(to_path('/root/not-packages.config')) }
    it { is_expected.not_to be_match(to_path('/root/simple.sln')) }
    it { is_expected.to be_match(to_path('/root/packages.config')) }
    it { is_expected.to be_match(to_path('./packages.config')) }
  end
end
