# frozen_string_literal: true

RSpec.describe ::Spandx::Core::Http do
  subject { described_class.new(retries: 1) }

  describe '#get' do
    context 'when a connection to a host failed previously' do
      let(:down_host) { 'nexus.example.com' }
      let(:up_host) { 'git.example.com' }

      before do
        down_url = "https://#{down_host}/#{SecureRandom.uuid}"
        stub_request(:get, down_url).to_timeout
        subject.get(down_url)
      end

      it 'stops attempting to connect to an unreachable host after `n` failures' do
        another_down_url = "https://#{down_host}/#{SecureRandom.uuid}"
        default_value = SecureRandom.uuid

        stub_request(:get, another_down_url).to_raise(StandardError)

        expect(subject.get(another_down_url, default: default_value)).to eql(default_value)
      end

      it 'continues to connect to hosts that are still up' do
        up_url = "https://#{up_host}/#{SecureRandom.uuid}"
        stub_request(:get, up_url).to_return(status: 200)

        expect(subject.get(up_url)).to be_a_kind_of(Net::HTTPSuccess)
      end
    end
  end
end
