# frozen_string_literal: true

RSpec.describe Spandx::Spdx::Gateway do
  describe '#fetch' do
    subject { described_class.new.fetch(http: http) }

    let(:url) { described_class::URL }
    let(:http) { Spandx::Core::Http.new }

    context 'when the licenses.json endpoint is healthy' do
      let(:spdx_json) { fixture_file_content('spdx/json/licenses.json') }
      let(:catalogue_hash) { JSON.parse(spdx_json, symbolize_names: true) }

      before do
        stub_request(:get, url).to_return(status: 200, body: spdx_json)
      end

      it { expect(subject).to eql(catalogue_hash) }
    end

    context 'when the licenses.json endpoint is not reachable' do
      before do
        stub_request(:get, url).to_return(status: 404)
      end

      it { expect(subject).to be_empty }
    end

    Net::Hippie::CONNECTION_ERRORS.each do |error|
      context "when an `#{error}` is raised while trying to connect to the endpoint" do
        before do
          # rubocop:disable RSpec/AnyInstance
          allow_any_instance_of(Net::Hippie::Client).to receive(:sleep)
          # rubocop:enable RSpec/AnyInstance
          stub_request(:get, url).and_raise(error)
        end

        it { expect(subject).to be_empty }
      end
    end
  end
end
