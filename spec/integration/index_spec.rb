# frozen_string_literal: true

RSpec.describe Spandx::OfflineIndex do
  describe '#licenses_for' do
    context 'when reading rubygems packages' do
      subject { described_class.new(db) }

      let(:db) do
        Spandx::Database.new(url: 'https://github.com/mokhan/spandx-rubygems.git').tap(&:update!)
      end

      it 'returns the list of licenses for a specific package/version' do
        expect(subject.licenses_for(name: 'net-hippie', version: '0.3.2')).to match_array(['MIT'])
      end
    end
  end
end
