RSpec.describe Spandx::Parsers::Sln do
  describe "#parse" do
    context "when parsing a sln file without any project references" do
      let(:sln) { fixture_file('nuget/empty.sln') }

      it 'returns an empty list of dependencies' do
        expect(subject.parse(sln)).to be_empty
      end
    end
  end
end
