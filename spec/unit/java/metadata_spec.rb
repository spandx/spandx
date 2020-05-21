# frozen_string_literal: true

RSpec.describe Spandx::Java::Metadata do
  describe '#licenses' do
    context 'when the metadata is invalid' do
      subject { described_class.new(artifact_id: '${project.artifactId}', group_id: '${project.groupId}', version: '${project.version}') }

      let(:result) { subject.licenses }

      specify { expect(result).to be_empty }
    end
  end
end
