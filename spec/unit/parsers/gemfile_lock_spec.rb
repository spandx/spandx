# frozen_string_literal: true

RSpec.describe Spandx::Parsers::GemfileLock do
  subject { described_class.new(catalogue: catalogue) }

  let(:catalogue) { instance_double(Spandx::Catalogue, :[] => nil) }

  describe '#parse' do
    context 'when parsing a Gemfile with a single dependency' do
      let(:lockfile) { File.join(Dir.pwd, 'spec', 'fixtures', 'bundler', 'Gemfile-single.lock') }

      it 'parses the lone dependency' do
        expect(subject.parse(lockfile).count).to be(1)
      end
    end
  end
end
