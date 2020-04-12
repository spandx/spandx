# frozen_string_literal: true

RSpec.describe Spandx::Core::LicensePlugin do
  subject { described_class.new }
  let(:catalogue) { ::Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

  describe '#enhance' do
    context 'when the dependency is not managed by a known package manager' do
      let(:dependency) { ::Spandx::Core::Dependency.new(package_manager: :unknown, name: 'spandx', version: '0.1.0') }

      specify { expect(subject.enhance(dependency)).to eql(dependency) }
    end

    [
      { package_manager: :nuget, name: 'NHibernate', version: '5.2.6', expected: ['LGPL-2.1-only'] },
      { package_manager: :nuget, name: 'System.Security.Principal.Windows', version: '4.3.0', expected: ['Nonstandard'] },
      { package_manager: :nuget, name: 'jive', version: '0.1.0', expected: ['MIT'] },
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
  end
end
