# frozen_string_literal: true

RSpec.describe Spandx::Php::PackagistGateway do
  subject { described_class.new }

  describe '#licenses_for' do
    let(:dependency) { instance_double(::Spandx::Core::Dependency, name: 'monolog/monolog', version: '3.10.0') }

    context 'when the package is reachable' do
      before do
        stub_request(:get, 'https://repo.packagist.org/p2/monolog/monolog.json').to_return(
          status: 200,
          body: JSON.generate(packages: { 'monolog/monolog' => [{ 'version' => '3.10.0', 'license' => ['MIT'] }] })
        )
      end

      specify { expect(subject.licenses_for(dependency)).to match_array(['MIT']) }
    end

    context 'when the package is not reachable' do
      before do
        stub_request(:get, 'https://repo.packagist.org/p2/monolog/monolog.json').to_return(status: 404)
      end

      specify { expect(subject.licenses_for(dependency)).to be_empty }
    end
  end

  describe '#each' do
    let(:names) { [] }

    before do
      stub_request(:get, described_class::LIST_URL).to_return(
        status: 200,
        body: JSON.generate(packageNames: ['monolog/monolog', 'symfony/console'])
      )

      subject.each { |name| names << name }
    end

    specify { expect(names).to match_array(['monolog/monolog', 'symfony/console']) }
  end

  describe '#metadata_for' do
    before do
      stub_request(:get, 'https://repo.packagist.org/p2/monolog/monolog.json').to_return(
        status: 200,
        body: JSON.generate(
          packages: {
            'monolog/monolog' => [
              { 'version' => '3.10.0', 'license' => ['MIT'] },
              { 'version' => '3.9.0', 'license' => ['MIT'] },
            ],
          }
        )
      )
    end

    specify { expect(subject.metadata_for('monolog/monolog').map { |x| x['version'] }).to match_array(['3.10.0', '3.9.0']) }
  end
end
