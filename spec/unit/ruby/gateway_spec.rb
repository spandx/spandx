# frozen_string_literal: true

RSpec.describe Spandx::Ruby::Gateway do
  subject { described_class.new }

  describe '#resolve' do
    before do
      stub_request(:get, 'https://rubygems.org/api/v2/rubygems/spandx/versions/0.0.0.json')
        .to_return(status: 200, body: JSON.generate(licenses: ['MIT']))
    end

    specify do
      subject.resolve(subject, name: 'spandx', version: '0.0.0') do |name, version, licenses|
        expect([name, version, licenses]).to eql(['spandx', '0.0.0', ['MIT']])
      end
    end
  end

  describe '#each_package' do
    let(:items) { [] }

    before do
      VCR.use_cassette('index.rubygems.org/versions') do
        subject.each_package do |item|
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
