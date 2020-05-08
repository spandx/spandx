# frozen_string_literal: true

RSpec.describe Spandx::Core::Cache do
  RSpec.shared_examples 'each data file' do |package_manager, key|
    describe "#licenses_for (#{package_manager})" do
      subject { described_class.new(package_manager, root: "#{Spandx.git[key].root}/.index") }

      (0x00..0xFF).map { |x| x.to_s(16).upcase.rjust(2, '0').downcase }.each do |hex|
        context hex do
          let(:path) { subject.expand_path("#{hex}/#{package_manager}") }

          it "is able to find all packages in the #{package_manager} index" do
            CSV.foreach(path) do |row|
              results = subject.licenses_for(row[0], row[1])
              expect(results).to match_array(row[2].split('-|-'))
            end
          end
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
        expect(subject.licenses_for(nil, '1.1.1')).to be_empty
      end

      specify do
        subject.insert('spandx', nil, ['MIT'])
        expect(File.exist?(File.join(root_dir, 'cf'))).to be(false)
      end

      specify do
        subject.insert('spandx', '', ['MIT'])
        expect(subject.licenses_for('', '1.1.1')).to be_empty
      end

      specify do
        subject.insert('spandx', '', ['MIT'])
        expect(File.exist?(File.join(root_dir, 'cf'))).to be(false)
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
      let(:index) { JSON.parse(IO.read(File.join(root_dir, 'cf', 'rubygems.lines'))) }

      before do
        subject.insert('spandx', '0.0.0', ['MIT'])
        subject.insert('bolt', '0.2.0', ['Apache-2.0'])
        subject.insert('spandx', '0.1.0', ['MIT'])

        subject.rebuild_index
      end

      it 'sorts each datafile' do
        lines = IO.readlines(File.join(root_dir, 'cf', 'rubygems'))
        expect(lines).to eql(lines.sort)
      end

      specify { expect(index).to be_instance_of(Array) }

      it 'stores an array that contains the position of the start of each line' do
        expect(index.count).to be(3)
      end

      # rubocop:disable RSpec/MultipleExpectations
      it 'builds an index that contains the seek address for the start of each line' do
        File.open(File.join(root_dir, 'cf', 'rubygems')) do |io|
          index.each do |position|
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
    subject { described_class.new('rubygems', root: root_dir) }

    let(:root_dir) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(root_dir)
    end

    context 'when a single item is present in the cache' do
      before do
        subject.insert('spandx', '0.0.0', ['MIT'])
      end

      it 'yields each item in the index' do
        collect = []

        subject.each do |item|
          collect << item
        end

        expect(collect).to match_array([['spandx', '0.0.0', 'MIT']])
      end
    end
  end
end
