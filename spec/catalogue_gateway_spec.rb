# frozen_string_literal: true

RSpec.describe Spandx::CatalogueGateway do
  describe "#fetch" do
    let(:result) { subject.fetch }
    let(:url) { described_class::URL }

    context "when the licenses.json endpoint is healthy" do
      let(:spdx_json) { IO.read(File.join("spec", "fixtures", "spdx.json")) }
      let(:catalogue_hash) { JSON.parse(spdx_json, symbolize_names: true) }

      before do
        stub_request(:get, url).to_return(status: 200, body: spdx_json)
      end

      it { expect(result.count).to be(catalogue_hash[:licenses].count) }
    end

    context "when the licenses.json endpoint is not reachable" do
      before do
        stub_request(:get, url).to_return(status: 404)
      end

      it { expect(result.count).to be_zero }
    end

    Net::Hippie::CONNECTION_ERRORS.each do |error|
      context "when an `#{error}` is raised while trying to connect to the endpoint" do
        before do
          stub_request(:get, url).and_raise(error)
        end

        it { expect(result.count).to be_zero }
      end
    end
  end
end
