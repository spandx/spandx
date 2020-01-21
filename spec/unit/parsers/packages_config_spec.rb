# frozen_string_literal: true

RSpec.describe Spandx::Parsers::PackagesConfig do
  subject { described_class.new(catalogue: catalogue) }

  let(:catalogue) { instance_double(Spandx::Catalogue, :[] => nil) }

  describe '#parse' do
    context 'when parsing a Gemfile with a single dependency' do
      let(:lockfile) { fixture_file('nuget/packages.config') }
      let(:because) do
        VCR.use_cassette(File.basename(lockfile)) do
          subject.parse(lockfile)
        end
      end

      it 'detects the listed dependencies' do
        expect(because.map(&:name)).to include('NHibernate')
      end

      it 'detects the dependencies of the listed dependencies' do
        expect(because.map(&:name)).to include('Antlr3.Runtime')
        expect(because.map(&:name)).to include('Iesi.Collections')
        expect(because.map(&:name)).to include('Remotion.Linq')
        expect(because.map(&:name)).to include('Remotion.Linq.EagerFetching')
      end
    end
  end
end
