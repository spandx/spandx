# frozen_string_literal: true

RSpec.describe Spandx::Php::LicensePlugin do
  subject { described_class.new }

  describe '#enhance' do
    context 'when the dependency is not managed by the `composer` package manager' do
      let(:dependency) { ::Spandx::Core::Dependency.new(package_manager: :rubygems, name: 'spandx', version: '0.1.0') }

      specify { expect(subject.enhance(dependency)).to eql(dependency) }
    end

    [
      { package_manager: :composer, name: 'doctrine/instantiator', version: '1.3.0', expected: ['MIT'] },
      { package_manager: :composer, name: 'hamcrest/hamcrest-php', version: 'v2.0.0', expected: ['Nonstandard'] },
      { package_manager: :composer, name: 'mockery/mockery', version: '1.3.1', expected: ['BSD-3-Clause'] },
      { package_manager: :composer, name: 'phpdocumentor/reflection-common', version: '2.0.0', expected: ['MIT'] },
      { package_manager: :composer, name: 'phpdocumentor/type-resolver', version: '1.0.1', expected: ['MIT'] },
      { package_manager: :composer, name: 'symfony/polyfill-ctype', version: 'v1.14.0', expected: ['MIT'] },
      { package_manager: :composer, name: 'webmozart/assert', version: '1.7.0', expected: ['MIT'] },
    ].each do |item|
      context "#{item[:package_manager]}-#{item[:name]}-#{item[:version]}" do
        let(:dependency) { ::Spandx::Core::Dependency.new(package_manager: item[:package_manager], name: item[:name], version: item[:version]) }

        let(:results) do
          VCR.use_cassette("#{item[:package_manager]}-#{item[:name]}-#{item[:version]}") do
            subject.enhance(dependency).licenses
          end
        end

        specify { expect(results.map(&:id)).to match_array(item[:expected]) }
      end
    end

    context 'when the metadata includes the detected license' do
      let(:dependency) { ::Spandx::Core::Dependency.new(package_manager: :composer, name: 'spandx/example', version: '0.1.0', meta: { 'license' => ['MIT'] }) }
      let(:results) { subject.enhance(dependency).licenses }

      it 'skips the network lookup' do
        expect(results.map(&:id)).to match_array(['MIT'])
      end
    end
  end
end
