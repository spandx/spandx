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

  describe "#insert" do
    subject { described_class.new('rubygems', root: root_dir) }

    let(:root_dir) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(root_dir)
    end

    context "when inserting a new record" do
      let(:dependency_name) { SecureRandom.uuid }
      let(:version) { "#{rand(10)}.#{rand(10)}.#{rand(10)}" }

      before do
        subject.insert(dependency_name, version, ['MIT'])
      end

      specify { expect(subject.licenses_for(dependency_name, version)).to match_array(['MIT']) }
    end
  end

  describe "#rebuild_index" do
    subject { described_class.new('rubygems', root: root_dir) }

    let(:root_dir) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(root_dir)
    end

    context "When new items are added to the catalogue" do
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

      it 'builds an index that contains the seek address for the start of each line'
    end
  end
end
