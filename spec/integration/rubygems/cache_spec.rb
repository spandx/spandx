# frozen_string_literal: true

RSpec.describe Spandx::Rubygems::Cache do
  subject { described_class.new(package_manager, url: url) }

  context "rubygems" do
    let(:package_manager) { :rubygems }
    let(:url) { "https://github.com/mokhan/spandx-#{package_manager}.git" }

    describe '#licenses_for' do
      (0x00..0xFF).map { |x| x.to_s(16).upcase.rjust(2, '0').downcase }.each do |hex|
        context hex do
          let(:path) { subject.db.expand_path(".index/#{hex}/#{package_manager}") }

          it 'is able to find all packages in the index' do
            CSV.foreach(path) do |row|
              results = subject.licenses_for(name: row[0], version: row[1])
              expect(results).to match_array(row[2].split('-|-'))
            end
          end
        end
      end

      it 'returns an empty list of unknown packages' do
        expect(subject.licenses_for(name: 'x', version: 'x')).to be_empty
      end
    end
  end

  context "nuget" do
    let(:package_manager) { :nuget }
    let(:url) { "https://github.com/mokhan/spandx-index.git" }

    describe '#licenses_for' do
      (0x00..0xFF).map { |x| x.to_s(16).upcase.rjust(2, '0').downcase }.each do |hex|
        context hex do
          let(:path) { subject.db.expand_path(".index/#{hex}/#{package_manager}") }

          it 'is able to find all packages in the index' do
            CSV.foreach(path) do |row|
              results = subject.licenses_for(name: row[0], version: row[1])
              expect(results).to match_array(row[2].split('-|-'))
            end
          end
        end
      end

      it 'returns an empty list of unknown packages' do
        expect(subject.licenses_for(name: 'x', version: 'x')).to be_empty
      end
    end
  end
end
