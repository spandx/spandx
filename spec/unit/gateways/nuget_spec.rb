RSpec.describe Spandx::Gateways::Nuget do
  subject { described_class.new(catalogue: catalogue) }
  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

  describe "#licenses_for" do
    context "when the package specifies the license using an expression" do
      specify do
        VCR.use_cassette('jive-0.1.0') do
          expect(subject.licenses_for('jive', '0.1.0')).to match_array(['MIT'])
        end
      end
    end

    pending "when the package specifies the license using a file"
    pending "when the package specifies the license using a url"
  end
end

