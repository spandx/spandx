# frozen_string_literal: true

RSpec.describe Spandx::Dotnet::Parsers::PackagesConfig do
  subject { described_class.new(catalogue: catalogue) }

  let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

  describe '#parse' do
    context 'when parsing a Gemfile with a single dependency' do
      let(:lockfile) { fixture_file('nuget/packages.config') }
      let(:because) { subject.parse(lockfile) }
      let(:nhibernate) { because.find { |item| item.name == 'NHibernate' } }

      specify { expect(nhibernate.name).to eql('NHibernate') }
      specify { expect(nhibernate.version).to eql('5.2.6') }
      pending { expect(because.map(&:name)).to include('Antlr3.Runtime') }
      pending { expect(because.map(&:name)).to include('Iesi.Collections') }
      pending { expect(because.map(&:name)).to include('Remotion.Linq') }
      pending { expect(because.map(&:name)).to include('Remotion.Linq.EagerFetching') }
    end
  end
end
