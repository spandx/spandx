# frozen_string_literal: true

RSpec.describe Spandx::Java::Metadata do
  describe '#licenses' do
    context 'when the metadata is invalid' do
      subject { described_class.new(artifact_id: '${project.artifactId}', group_id: '${project.groupId}', version: '${project.version}') }

      let(:result) { subject.licenses }

      specify { expect(result).to be_empty }
    end
  end

  describe '#licenses_from' do
    subject { described_class.new(artifact_id: 'spandx', group_id: 'org.example', version: '1.0.0') }

    let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

    before do
      stub_request(:get, 'https://repo.maven.apache.org/maven2/org/example/spandx/1.0.0/spandx-1.0.0.pom').to_return(
        status: 200,
        body: '<project><licenses><license><name>MIT</name><url>https://opensource.org/licenses/MIT</url></license></licenses></project>'
      )
    end

    specify { expect(subject.licenses_from(catalogue)).to eql(['MIT']) }
  end
end
