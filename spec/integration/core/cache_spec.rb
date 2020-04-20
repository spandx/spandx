# frozen_string_literal: true

RSpec.describe Spandx::Core::Cache do
  RSpec.shared_examples 'each data file' do |package_manager, key|
    describe "#licenses_for (#{package_manager})" do
      subject { described_class.new(package_manager, root: Spandx.git[key].path) }

      (0x00..0xFF).map { |x| x.to_s(16).upcase.rjust(2, '0').downcase }.each do |hex|
        context hex do
          let(:path) { subject.expand_path(".index/#{hex}/#{package_manager}") }

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
end
