RSpec.describe Spandx::Ruby::Gateway do
  subject { described_class.new }

  describe '#each' do
    let(:items) { [] }

    before do
      VCR.use_cassette('index.rubygems.org/versions') do
        subject.each do |item|
          items << item
        end
      end
    end

    specify { expect(items.count).to be(1_110_304) }
    specify { expect(items[0][:name]).to eql('-') }
    specify { expect(items[0][:version]).to eql('1') }
    specify { expect(items[-1][:name]).to eql('rpg_paradise') }
    specify { expect(items[-1][:version]).to eql('0.0.190') }
  end
end
