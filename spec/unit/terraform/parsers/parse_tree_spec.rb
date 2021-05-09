# frozen_string_literal: true

RSpec.describe Spandx::Terraform::Parsers::ParseTree do
  subject(:parser) { described_class.new }

  describe '#parse' do
    subject { parser.parse_with_debug(content) }

    context "when parsing an empty provider block" do
      let(:content) do
        <<~HCL
        provider "registry.terraform.io/hashicorp/aws" {

        }
        HCL
      end

      specify { expect(subject[0].dig(:provider, :name).to_s).to eql('registry.terraform.io/hashicorp/aws') }
      specify { expect(subject).to be_truthy }
    end
  end
end
