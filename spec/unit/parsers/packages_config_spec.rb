# frozen_string_literal: true

RSpec.describe Spandx::Parsers::PackagesConfig do
  subject { described_class.new(catalogue: catalogue) }

  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

  describe '#parse' do
    context 'when parsing a Gemfile with a single dependency' do
      let(:lockfile) { fixture_file('nuget/packages.config') }
      let(:because) do
        VCR.use_cassette(File.basename(lockfile)) do
          subject.parse(lockfile)
        end
      end
      let(:nhibernate) { because.find { |item| item.name == 'NHibernate' } }

      specify { expect(nhibernate.name).to eql('NHibernate') }
      specify { expect(nhibernate.version).to eql('5.2.6') }
      specify { expect(nhibernate.licenses.map(&:id)).to match_array(['LGPL-2.1-only']) }
      pending { expect(because.map(&:name)).to include('Antlr3.Runtime') }
      pending { expect(because.map(&:name)).to include('Iesi.Collections') }
      pending { expect(because.map(&:name)).to include('Remotion.Linq') }
      pending { expect(because.map(&:name)).to include('Remotion.Linq.EagerFetching') }
    end
  end
end
