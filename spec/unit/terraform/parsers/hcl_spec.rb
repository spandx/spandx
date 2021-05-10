# frozen_string_literal: true

RSpec.describe Spandx::Terraform::Parsers::Hcl do
  subject(:parser) { described_class.new }

  describe '#parse' do
    subject { parser.parse_with_debug(content) }

    context 'when parsing an empty provider block' do
      let(:content) do
        <<~HCL
          # This file is maintained automatically by "terraform init".
          # Manual edits may be lost in future updates.

          provider "registry.terraform.io/hashicorp/aws" {
            version     = "3.39.0"
            constraints = "~> 3.27"
            hashes = [
              "h1:fjlp3Pd3QsTLghNm7TUh/KnEMM2D3tLb7jsDLs8oWUE=",
              "zh:2014b397dd93fa55f2f2d1338c19e5b2b77b025a76a6b1fceea0b8696e984b9c",
              "zh:23d59c68ab50148a0f5c911a801734e9934a1fccd41118a8efb5194135cbd360",
              "zh:412eab41d4934ca9c47083faa128e4cd585c3bb44ad718e40d67091aebc02f4e",
              "zh:4b75e0a259b56d97e66b7d69f3f25bd4cc7be2440c0fe35529f46de7d40a49d3",
              "zh:694a32519dcca5bd8605d06481d16883d55160d97c1f4039deb13c6ca8de8427",
              "zh:6a0bcef43c2d9a97aeaaac3c5d1d6728dc2464a51a014f118c691c79029d0903",
              "zh:6d78fc7c663247ca2a80f276008dcdafece4cac75e2639bbce188c08b796040a",
              "zh:78f846a505d7b64b67feed1527d4d2b40130dadaf8e3112113685e148f49b156",
              "zh:881bc969432d3ef6ec70f5a762c3415e037904338579b0a360c6818b74d26e59",
              "zh:96c1ca80c1d693a3eef80489adb45c076ee8e6878e461d6c29b05388d4b95f48",
              "zh:9be5fa342272586fc6e319e20f21c0c5c801b05dcf7d59e473ad0882c9ecfa70",
            ]
          }

          /*
            This is a multi-line comment
            that spans multiple lines
          */
        HCL
      end

      specify { expect(subject).to be_truthy }
      specify { expect(subject[:blocks][0][:name].to_s).to eql('registry.terraform.io/hashicorp/aws') }
      specify { expect(subject[:blocks][0][:type].to_s).to eql('provider') }

      specify do
        expect(subject[:blocks][0][:arguments]).to match_array([
          { name: 'version', value: '3.39.0' },
          { name: 'constraints', value: '~> 3.27' },
          {
            name: 'hashes',
            values: [
              { value: 'h1:fjlp3Pd3QsTLghNm7TUh/KnEMM2D3tLb7jsDLs8oWUE=' },
              { value: 'zh:2014b397dd93fa55f2f2d1338c19e5b2b77b025a76a6b1fceea0b8696e984b9c' },
              { value: 'zh:23d59c68ab50148a0f5c911a801734e9934a1fccd41118a8efb5194135cbd360' },
              { value: 'zh:412eab41d4934ca9c47083faa128e4cd585c3bb44ad718e40d67091aebc02f4e' },
              { value: 'zh:4b75e0a259b56d97e66b7d69f3f25bd4cc7be2440c0fe35529f46de7d40a49d3' },
              { value: 'zh:694a32519dcca5bd8605d06481d16883d55160d97c1f4039deb13c6ca8de8427' },
              { value: 'zh:6a0bcef43c2d9a97aeaaac3c5d1d6728dc2464a51a014f118c691c79029d0903' },
              { value: 'zh:6d78fc7c663247ca2a80f276008dcdafece4cac75e2639bbce188c08b796040a' },
              { value: 'zh:78f846a505d7b64b67feed1527d4d2b40130dadaf8e3112113685e148f49b156' },
              { value: 'zh:881bc969432d3ef6ec70f5a762c3415e037904338579b0a360c6818b74d26e59' },
              { value: 'zh:96c1ca80c1d693a3eef80489adb45c076ee8e6878e461d6c29b05388d4b95f48' },
              { value: 'zh:9be5fa342272586fc6e319e20f21c0c5c801b05dcf7d59e473ad0882c9ecfa70' },
            ]
          },
        ])
      end
    end
  end

  describe '#version_assignment' do
    subject { parser.version_assignment }

    [
      'version     = "3.39.0"',
      'version     = "3.39.0-alpha"',
      'version     = "3.39.0-beta"',
      'version     = "3.39.0-d15aad9f"',
      'version     = "3.39.0-d15aad9f6ad69c4248a70b11a6534c1c841ec6f9"',
      'version = "3.39.0"',
      'version = "3.39.0-alpha"',
      'version = "3.39.0-beta"',
      'version = "3.39.0-d15aad9f"',
      'version = "3.39.0-d15aad9f6ad69c4248a70b11a6534c1c841ec6f9"',
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

  describe '#constraint_assignment' do
    subject { parser.constraint_assignment }

    [
      'constraints = ">= 3"',
      'constraints = ">= 3.27"',
      'constraints = ">= 3.27.0"',
      'constraints = "~> 3"',
      'constraints = "~> 3.27"',
      'constraints = "~> 3.27.0"',
    ].each do |raw|
      specify { expect(subject).to parse(raw) }
    end
  end

  describe '#version_constraint' do
    [
      '~> 3',
      '~> 3.27',
      '~> 3.27.0',
      '>= 1.2.0',
      '>= 1.20',
      '>= 10',
    ].each do |raw|
      specify { expect(parser.version_constraint).to parse(raw) }
    end
  end

  (('a'..'z').to_a + ('A'..'Z').to_a).each do |letter|
    specify { expect(parser.alpha).to parse(letter) }
  end

  (0..9).each { |digit| specify { expect(parser.digit).to parse(digit.to_s) } }
  specify { expect(parser.assign).to parse('=') }
  specify { expect(parser.comment).to parse('# Manual edits may be lost in future updates.') }
  specify { expect(parser.comment).to parse('# This file is maintained automatically by "terraform init".') }
  specify { expect(parser.comment).to parse('// This file is maintained automatically by "terraform init".') }
  specify { expect(parser.crlf).to parse("\n") }
  specify { expect(parser.crlf).to parse("\r") }
  specify { expect(parser.dot).to parse('.') }
  specify { expect(parser.eol).to parse(" \n") }
  specify { expect(parser.eol).to parse("\n") }
  specify { expect(parser.lcurly).to parse('{') }
  specify { expect(parser.number).to parse('123') }
  specify { expect(parser.quote).to parse('"') }
  specify { expect(parser.rcurly).to parse('}') }
  specify { expect(parser.space).to parse(' ') }
  specify { expect(parser.whitespace).to parse('# This is a comment') }
  specify { expect(parser.whitespace).to parse('// This is a comment') }

  specify do
    expect(parser.whitespace).to parse(<<~HCL)
      /*
        This is a multi-line comment
        that spans multiple lines
      */
    HCL
  end

  specify { expect(parser.argument).to parse('constraints = "~> 3.27"') }

  specify do
    expect(parser.argument).to parse(<<~HCL.chomp)
      hashes = [
        "h1:fjlp3Pd3QsTLghNm7TUh/KnEMM2D3tLb7jsDLs8oWUE=",
        "zh:2014b397dd93fa55f2f2d1338c19e5b2b77b025a76a6b1fceea0b8696e984b9c",
        "zh:23d59c68ab50148a0f5c911a801734e9934a1fccd41118a8efb5194135cbd360",
        "zh:412eab41d4934ca9c47083faa128e4cd585c3bb44ad718e40d67091aebc02f4e",
        "zh:4b75e0a259b56d97e66b7d69f3f25bd4cc7be2440c0fe35529f46de7d40a49d3",
        "zh:694a32519dcca5bd8605d06481d16883d55160d97c1f4039deb13c6ca8de8427",
        "zh:6a0bcef43c2d9a97aeaaac3c5d1d6728dc2464a51a014f118c691c79029d0903",
        "zh:6d78fc7c663247ca2a80f276008dcdafece4cac75e2639bbce188c08b796040a",
        "zh:78f846a505d7b64b67feed1527d4d2b40130dadaf8e3112113685e148f49b156",
        "zh:881bc969432d3ef6ec70f5a762c3415e037904338579b0a360c6818b74d26e59",
        "zh:96c1ca80c1d693a3eef80489adb45c076ee8e6878e461d6c29b05388d4b95f48",
        "zh:9be5fa342272586fc6e319e20f21c0c5c801b05dcf7d59e473ad0882c9ecfa70",
      ]
    HCL
  end
end
