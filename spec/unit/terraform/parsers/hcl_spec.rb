# frozen_string_literal: true

RSpec.describe Spandx::Terraform::Parsers::Hcl do
  subject(:parser) { described_class.new }

  describe '#parse' do
    subject { parser.parse_with_debug(content) }

    context 'when parsing an empty provider block' do
      let(:content) do
        <<~HCL
          provider "registry.terraform.io/hashicorp/aws" {
            version     = "3.39.0"
          }
        HCL
      end

      specify { expect(subject[0].dig(:provider, :name).to_s).to eql('registry.terraform.io/hashicorp/aws') }
      specify { expect(subject[0].dig(:provider, :version).to_s).to eql('3.39.0') }
      specify { expect(subject).to be_truthy }
    end
  end

  describe '#version_assignment' do
    subject { parser.version_assignment }

    [
      'version     = "3.39.0"',
      'version     = "3.39.0-alpha"',
      'version     = "3.39.0-beta"',
      'version     = "3.39.0-d15aad9f6ad69c4248a70b11a6534c1c841ec6f9"',
      'version     = "3.39.0-d15aad9f"',
    ].each do |raw|
      specify { expect(subject).to parse(raw) }
    end
  end

  describe '#version' do
    [
      '0.1.1-alpha',
      '0.1.1-beta',
      '1.2.3',
      '3.39.0',
      '3.39.0-d15aad9f',
      '3.39.0-d15aad9f6ad69c4248a70b11a6534c1c841ec6f9',
    ].each do |raw|
      specify { expect(parser.version).to parse(raw) }
    end
  end

  (('a'..'z').to_a + ('A'..'Z').to_a).each do |letter|
    specify { expect(parser.alpha).to parse(letter) }
  end

  (0..9).each { |digit| specify { expect(parser.digit).to parse(digit.to_s) } }
  specify { expect(parser.assign).to parse('=') }
  specify { expect(parser.crlf).to parse("\n") }
  specify { expect(parser.crlf).to parse("\r") }
  specify { expect(parser.dot).to parse('.') }
  specify { expect(parser.eol).to parse("\n") }
  specify { expect(parser.eol).to parse(" \n") }
  specify { expect(parser.lcurly).to parse('{') }
  specify { expect(parser.number).to parse('123') }
  specify { expect(parser.rcurly).to parse('}') }
  specify { expect(parser.quote).to parse('"') }
  specify { expect(parser.space).to parse(' ') }
end
