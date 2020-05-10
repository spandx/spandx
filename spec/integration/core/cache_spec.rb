# frozen_string_literal: true

RSpec.describe Spandx::Core::Cache do
  RSpec.shared_examples 'each data file' do |package_manager, key|
    describe "#licenses_for(#{package_manager})" do
      subject { described_class.new(package_manager, root: root_dir) }

      let(:root_dir) { "#{Spandx.git[key].root}/.index" }

      it 'finds each package quickly' do
        subject.take(10).each do |item|
          expect do
            subject.licenses_for(item[0], item[1])
          end.to perform_under(0.005).sample(10)
        end
      end

      it 'finds each package correctly' do
        subject.take(100).each do |item|
          result = subject.licenses_for(item[0], item[1])
          expect(result).to match_array([item[2]].reject(&:nil?).reject(&:empty?)), "Could not find #{item[0]}:#{item[1]}"
        end
      end

      it 'returns an empty list of unknown packages' do
        expect(subject.licenses_for('x', 'x')).to be_empty
      end
    end
  end

  include_examples 'each data file', 'rubygems', :rubygems
  include_examples 'each data file', 'nuget', :cache

  describe '#insert' do
    subject { described_class.new('rubygems', root: root_dir) }

    let(:root_dir) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(root_dir)
    end

    context 'when inserting a new record' do
      let(:dependency_name) { SecureRandom.uuid }
      let(:version) { "#{rand(10)}.#{rand(10)}.#{rand(10)}" }

      before do
        subject.insert(dependency_name, version, ['MIT'])
      end

      specify { expect(subject.licenses_for(dependency_name, version)).to match_array(['MIT']) }
    end

    context 'when attempting to insert invalid entries' do
      specify do
        subject.insert(nil, '1.1.1', ['MIT'])
        expect(subject.licenses_for(nil, '1.1.1')).to be_empty
      end

      specify do
        subject.insert('', '1.1.1', ['MIT'])
        expect(subject.licenses_for('', '1.1.1')).to be_empty
      end

      specify do
        subject.insert('spandx', nil, ['MIT'])
        expect(subject.licenses_for('spandx', nil)).to be_empty
      end

      specify do
        subject.insert('spandx', nil, ['MIT'])
        expect(File.exist?(File.join(root_dir, 'cf', subject.package_manager))).to be(false)
      end

      specify do
        subject.insert('spandx', '', ['MIT'])
        expect(subject.licenses_for('spandx', '')).to be_empty
      end

      specify do
        subject.insert('spandx', '', ['MIT'])
        expect(File.exist?(File.join(root_dir, 'cf', subject.package_manager))).to be(false)
      end
    end
  end

  describe '#rebuild_index' do
    subject { described_class.new('rubygems', root: root_dir) }

    let(:root_dir) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(root_dir)
    end

    context 'when new items are added to the catalogue' do
      before do
        subject.insert('spandx', '0.0.0', ['MIT'])
        subject.insert('bolt', '0.2.0', ['Apache-2.0'])
        subject.insert('spandx', '0.1.0', ['MIT'])

        subject.rebuild_index
      end

      it 'sorts each datafile' do
        lines = subject.datafile_for('spandx').absolute_path.readlines
        expect(lines).to eql(lines.sort)
      end

      # rubocop:disable RSpec/MultipleExpectations
      it 'builds an index that contains the seek position for the start of each line' do
        data_file = subject.datafile_for('spandx')
        data_file.open_file do |io|
          data_file.index.each do |position|
            unless position.zero?
              io.seek(position - 1)
              expect(io.readchar).to eql("\n")
            end
            expect(io.readchar).not_to eql("\n")
          end
        end
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end

  describe '#each' do
    context 'when a single item is present in the cache' do
      subject { described_class.new('rubygems', root: root_dir) }

      let(:root_dir) { Dir.mktmpdir }

      before do
        subject.insert('spandx', '0.0.0', ['MIT'])
      end

      after do
        FileUtils.remove_entry(root_dir)
      end

      it 'yields each item in the cache' do
        collect = []

        subject.each do |item|
          collect << item
        end

        expect(collect).to match_array([['spandx', '0.0.0', 'MIT']])
      end
    end

    context 'when multiple items are in multiple datafiles' do
      subject { described_class.new('rubygems', root: root_dir) }

      let(:root_dir) { "#{Spandx.git[:rubygems].root}/.index" }

      it 'yields each item in the cache' do
        expect(subject.count).to be > 800_000
      end

      it 'yields each item quickly' do
        expect { subject.take(100_000).count }.to perform_under(0.1).sample(10)
      end
    end
  end
end
