# frozen_string_literal: true

RSpec.describe Spandx::Gateways::Spdx do
  describe '#fetch' do
    let(:result) { subject.fetch }
    let(:url) { described_class::URL }

    context 'when the licenses.json endpoint is healthy' do
      let(:spdx_json) { fixture_file_content('spdx/json/licenses.json') }
      let(:catalogue_hash) { JSON.parse(spdx_json, symbolize_names: true) }

      before do
        stub_request(:get, url).to_return(status: 200, body: spdx_json)
      end

      it { expect(result).to eql(catalogue_hash) }
    end

    context 'when the licenses.json endpoint is not reachable' do
      before do
        stub_request(:get, url).to_return(status: 404)
      end

      it { expect(result).to be_empty }
    end

    Net::Hippie::CONNECTION_ERRORS.each do |error|
      context "when an `#{error}` is raised while trying to connect to the endpoint" do
        before do
          # rubocop:disable RSpec/AnyInstance
          allow_any_instance_of(Net::Hippie::Client).to receive(:sleep)
          # rubocop:enable RSpec/AnyInstance
          stub_request(:get, url).and_raise(error)
        end

        it { expect(result).to be_empty }
      end
    end
  end
end
