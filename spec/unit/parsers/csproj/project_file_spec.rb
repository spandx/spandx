# frozen_string_literal: true

RSpec.describe Spandx::Parsers::Csproj::ProjectFile do
  subject { described_class.new(path) }

  describe '#package_references' do
    context 'simple.csproj' do
      let(:path) { fixture_file('nuget/example.csproj') }

      specify { expect(subject.package_references.count).to be(1) }
      specify { expect(subject.package_references[0].name).to eql('jive') }
      specify { expect(subject.package_references[0].version).to eql('0.1.0') }
    end

    context 'Packages.props' do
      let(:path) { fixture_file('nuget/Packages.props') }

      specify { expect(subject.package_references.count).to eq(16) }

      specify do
        expect(subject.package_references.map(&:to_h)).to match_array([
          { name: 'MSBuild.ProjectCreation', version: '1.3.1' },
          { name: 'McMaster.Extensions.CommandLineUtils', version: '2.5.0' },
          { name: 'Microsoft.Build', version: '16.4.0' },
          { name: 'Microsoft.Build.Artifacts', version: '2.0.1' },
          { name: 'Microsoft.Build.Locator', version: '1.2.6' },
          { name: 'Microsoft.Build.Runtime', version: '16.4.0' },
          { name: 'Microsoft.Build.Utilities.Core', version: '16.4.0' },
          { name: 'Microsoft.NET.Test.Sdk', version: '16.4.0' },
          { name: 'Microsoft.NETFramework.ReferenceAssemblies', version: '1.0.0' },
          { name: 'Microsoft.VisualStudio.Telemetry', version: '16.3.2' },
          { name: 'Nerdbank.GitVersioning', version: '3.0.28' },
          { name: 'Shouldly', version: '3.0.2' },
          { name: 'SlnGen', version: '2.2.30' },
          { name: 'StyleCop.Analyzers', version: '1.1.118' },
          { name: 'xunit', version: '2.4.1' },
          { name: 'xunit.runner.visualstudio', version: '2.4.1' },
        ])
      end
    end
  end
end
