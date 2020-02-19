# frozen_string_literal: true

RSpec.describe Spandx::OfflineIndex do
  describe '#licenses_for' do
    context 'when reading rubygems packages' do
      subject { described_class.new(db) }

      let(:db) { Spandx::Database.new(url: 'https://github.com/mokhan/spandx-rubygems.git').tap(&:update!) }

      it 'returns the list of licenses for a specific package/version' do
        expect(subject.licenses_for(name: 'net-hippie', version: '0.3.2')).to match_array(['MIT'])
      end

      (0x00..0xFF).map { |x| x.to_s(16).upcase.rjust(2, '0') }.each do |hex|
        context hex do
          let(:path) { db.expand_path("lib/spandx/rubygems/index/#{hex}/data") }

          it 'is able to find all packages in the index' do
            CSV.foreach(path) do | row|
              results = subject.licenses_for(name: row[0], version: row[1])
              expect(results).to match_array(row[2].split('-|-'))
            end
          end
        end
      end
    end
  end
end
