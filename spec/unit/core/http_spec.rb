# frozen_string_literal: true

RSpec.describe ::Spandx::Core::Http do
  subject { described_class.new(retries: 1) }

  describe '#get' do
    context 'when a request times out' do
      it 'returns the default value' do
        url = "https://nexus.example.com/#{SecureRandom.uuid}"
        default_value = SecureRandom.uuid
        stub_request(:get, url).to_timeout

        expect(subject.get(url, default: default_value)).to eql(default_value)
      end
    end

    context 'when a previous request to a host failed' do
      let(:host) { 'nexus.example.com' }

      before do
        down_url = "https://#{host}/#{SecureRandom.uuid}"
        stub_request(:get, down_url).to_timeout
        subject.get(down_url)
      end

      it 'still attempts subsequent requests to that host' do
        url = "https://#{host}/#{SecureRandom.uuid}"
        stub_request(:get, url).to_return(status: 200)

        expect(subject.get(url)).to be_a(Net::HTTPSuccess)
      end
    end
  end
end
