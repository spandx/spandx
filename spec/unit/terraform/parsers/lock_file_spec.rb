# frozen_string_literal: true

RSpec.describe Spandx::Terraform::Parsers::LockFile do
  subject(:parser) { described_class.new }

  describe '#parse' do
    def build(name, version, path)
      Spandx::Core::Dependency.new(name: name, version: version, path: path)
    end

    context "when parsing a .terraform.lock.hcl file" do
      subject { parser.parse(path) }

      let(:path) { fixture_file('terraform/simple/.terraform.lock.hcl') }

      specify { expect(subject).to match_array([build('registry.terraform.io/hashicorp/aws', '0.39.0', path)]) }
    end
  end
end
