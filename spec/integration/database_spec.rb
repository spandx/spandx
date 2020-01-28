# frozen_string_literal: true

RSpec.describe Spandx::Database do
  subject { described_class.new(url: url) }

  let(:url) { 'https://github.com/spdx/license-list-data.git' }
  let(:shell) { subject }

  before do
    allow(shell).to receive(:system)
  end

  describe '#url' do
    it { expect(subject.url).to eql(url) }
  end

  describe '#path' do
    let(:expected_path) { File.expand_path(File.join(ENV['HOME'], '.local', 'share', 'spdx', 'license-list-data')) }

    it { expect(subject.path).to eql(expected_path) }
  end

  describe 'update!' do
    let(:expected_path) { File.expand_path(File.join(ENV['HOME'], '.local', 'share', 'spdx', 'license-list-data')) }

    context 'when the repository has not been cloned' do
      before do
        subject.update!
      end

      specify { expect(shell).to have_received(:system).with('git', 'clone', url, expected_path) }
    end

    context 'when the repository has already been cloned' do
      before do
        allow(File).to receive(:directory?).with(File.join(expected_path, '.git')).and_return(true)

        subject.update!
      end

      it { expect(shell).to have_received(:system).with('git', 'pull', '--no-rebase', 'origin', 'master') }
    end
  end
end
