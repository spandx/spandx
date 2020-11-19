# frozen_string_literal: true

RSpec.describe Spandx::Core::Git do
  subject { described_class.new(url: url) }

  let(:url) { 'https://github.com/spdx/license-list-data.git' }
  let(:shell) { subject }

  before do
    allow(shell).to receive(:system)
  end

  describe '#url' do
    it { expect(subject.url).to eql(url) }
  end

  describe '#root' do
    let(:expected_path) { File.expand_path(File.join(ENV['HOME'], '.local', 'share', 'spdx', 'license-list-data')) }

    it { expect(subject.root.to_s).to eql(expected_path) }
  end

  describe 'update!' do
    let(:expected_path) { File.expand_path(File.join(ENV['HOME'], '.local', 'share', 'spdx', 'license-list-data')) }

    context 'when the repository has not been cloned' do
      let(:git_path) { instance_double(Pathname, directory?: false) }

      before do
        allow(subject.root).to receive(:join).with('.git').and_return(git_path)

        subject.update!
      end

      specify { expect(shell).to have_received(:system).with('git', 'clone', '--quiet', '--depth=1', '--single-branch', '--branch', 'main', url, expected_path, exception: true) }
    end

    context 'when the repository has already been cloned' do
      let(:git_path) { instance_double(Pathname, directory?: true) }

      before do
        allow(subject.root).to receive(:join).with('.git').and_return(git_path)
        allow(Dir).to receive(:chdir).with(Pathname(expected_path)).and_yield

        subject.update!
      end

      it { expect(shell).to have_received(:system).with('git', 'fetch', '--quiet', '--depth=1', '--prune', '--no-tags', 'origin', exception: true) }
    end
  end
end
