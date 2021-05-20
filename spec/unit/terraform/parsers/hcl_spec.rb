# frozen_string_literal: true

RSpec.describe Spandx::Terraform::Parsers::Hcl do
  subject(:parser) { described_class.new }

  describe '#parse' do
    subject { parser.parse_with_debug(content) }

    context 'when parsing a single provider' do
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

    context 'when parsing multiple provider blocks' do
      let(:content) { fixture_file_content('terraform/multiple_providers/.terraform.lock.hcl') }

      specify { expect(subject).to be_truthy }
      specify { expect(subject[:blocks][0][:name].to_s).to eql('registry.terraform.io/hashicorp/aws') }
      specify { expect(subject[:blocks][0][:type].to_s).to eql('provider') }
      specify { expect(subject[:blocks][1][:name].to_s).to eql('registry.terraform.io/hashicorp/azurerm') }
      specify { expect(subject[:blocks][1][:type].to_s).to eql('provider') }

      specify do
        expect(subject[:blocks][0][:arguments]).to match_array([
          { name: 'version', value: '3.40.0' },
          { name: 'constraints', value: '~> 3.27' },
          {
            name: 'hashes',
            values: [
              { value: 'h1:0r9TS3qACD9xJhrfTPZR7ygoCKDWHRX4c0D5GCyfAu4=' },
              { value: 'zh:2fd824991b19837e200d19b17d8188bf71efb92c36511809484549e77b4045dd' },
              { value: 'zh:47250cb58b3bd6f2698ca17bfb962710542d6adf95637cd560f6119abf97dba2' },
              { value: 'zh:515722a8c8726541b05362ec71331264977603374a2e4d4d64f89940873143ea' },
              { value: 'zh:61b6b7542da2113278c987a0af9f230321f5ed605f1e3098824603cb09ac771b' },
              { value: 'zh:66aad13ada6344b64adbc67abad4f35c414e62838a99f78626befb8b74c760d8' },
              { value: 'zh:7d4436aeb53fa348d7fd3c2ab4a727b03c7c59bfdcdecef4a75237760f3bb3cf' },
              { value: 'zh:a4583891debc49678491510574b1c28bb4fe3f83ed2bb353959c4c1f6f409f1f' },
              { value: 'zh:b8badecea52f6996ae832144560be87e0b7c2da7fe1dcd6e6230969234b2fc55' },
              { value: 'zh:cecf64a085f640c30437ccc31bd964c21004ae8ae00cfbd95fb04037e46b88ca' },
              { value: 'zh:d81dbb9ad8ce5eca4d1fc5a7a06bbb9c47ea8691f1502e94760fa680e20e4afc' },
              { value: 'zh:f0fc724a964c7f8154bc5911d572ee411f5d181414f9b1f09de7ebdacb0d884b' },
            ]
          },
        ])
      end

      specify do
        expect(subject[:blocks][1][:arguments]).to match_array([
          { name: 'version', value: '2.59.0' },
          { name: 'constraints', value: '~> 2.1' },
          {
            name: 'hashes',
            values: [
              { value: 'h1:Mp7ECMHocobalN1+ASSKG5dHB7RnhZ6Y0rEEFTT5urA=' },
              { value: 'zh:0996d1c85bccdb15aeb6bc32f763c2d85ff854b33c3c3d62c34859669e05785e' },
              { value: 'zh:37807677e68058381514897ce10dc73a0dd0f503aba98113ac79844d310010e3' },
              { value: 'zh:3bccf9215bdbcc89327582b1d9d2a633c59215ca6452dbb4f9d0a7a661074c5b' },
              { value: 'zh:4801791332ab81e51d1ead47a62e0081ec4c1f23ef0fc2e8b15fef315ecdf07a' },
              { value: 'zh:5bad44816a3eaeb335f665f6eef9b41a403a40e9bddb2db8406ab0e847f639ca' },
              { value: 'zh:64f79c4ddc2bf8384f1a42c4e430ffdc53cb1fbc565bfe1cdc6b075dcdf098e9' },
              { value: 'zh:75c96fcb592ed80cc403944faadda25aeadda7fd6de9162a8d365249b1ec1c17' },
              { value: 'zh:8604558f2f201eefe25f4c611a5d4ef4d7c75338bf2f4a6321da5caa94937947' },
              { value: 'zh:cab930e374d33b3b980c6774f3d0ac3e3d7e1e596aba586d4368d8bcf05cf9c5' },
              { value: 'zh:cf0e78eb1e84b6dd11031283878e392e55801e3acd9c5592309e6f76ebe3a621' },
              { value: 'zh:eba02fcab150775b8b8beeec0c7dbba1585a57f4e97272f48c71021c5e289579' },
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
  specify { expect(parser.assign).not_to parse('==') }
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
  specify { expect(parser.string).to parse('"h1:fjlp3Pd3QsTLghNm7TUh/KnEMM2D3tLb7jsDLs8oWUE="') }
  specify { expect(parser.string).to parse('"zh:2014b397dd93fa55f2f2d1338c19e5b2b77b025a76a6b1fceea0b8696e984b9c"') }

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

  specify do
    expect(parser.block).to parse(<<~HCL.chomp)
      provider "thing" {
        argument = "value"
        arguments = [
          "value",
          "value",
        ]
      }
    HCL
  end

  specify do
    expect(parser.block_body.parse_with_debug(<<~HCL.chomp)).not_to be_nil
      {
        argument = "value"
        arguments = [
          "value",
          "value",
        ]
      }
    HCL
  end

  specify { expect(parser.argument).to parse('argument = "value"') }

  specify do
    expect(parser.argument).to parse(<<~HCL)
      arguments = [
        "a",
        "b",
      ]
    HCL
  end

  describe '#blocks' do
    subject { parser.blocks.parse_with_debug(hcl) }

    context 'when parsing multiple multi-line empty blocks' do
      let(:hcl) do
        <<~HCL
          provider "thingy" {
          }

          provider "other.thingy" {
          }
        HCL
      end

      it 'parses multiple empty blocks' do
        expect(subject[:blocks]).to match_array([
          { type: 'provider', name: 'thingy', arguments: [] },
          { type: 'provider', name: 'other.thingy', arguments: [] },
        ])
      end
    end

    context 'when parsing multiple multi-line blocks with one argument assignment to a string in the first block' do
      let(:hcl) do
        <<~HCL
          provider "thingy" {
            name = "blah"
          }

          provider "other.thingy" {
          }
        HCL
      end

      it 'parses multiple empty blocks' do
        expect(subject[:blocks]).to match_array([
          { type: 'provider', name: 'thingy', arguments: [{ name: 'name', value: 'blah' }] },
          { type: 'provider', name: 'other.thingy', arguments: [] },
        ])
      end
    end

    context 'when parsing multiple multi-line blocks with one argument assignment to a string in the second block' do
      let(:hcl) do
        <<~HCL
          provider "thingy" {
          }

          provider "other.thingy" {
            name = "blah"
          }
        HCL
      end

      it 'parses multiple empty blocks' do
        expect(subject[:blocks]).to match_array([
          { type: 'provider', name: 'thingy', arguments: [] },
          { type: 'provider', name: 'other.thingy', arguments: [{ name: 'name', value: 'blah' }] },
        ])
      end
    end

    context 'when parsing a blocks with one assignment to an empty array' do
      let(:hcl) do
        <<~HCL
          provider "thingy" {
            names = [
            ]
          }
        HCL
      end

      pending 'parses multiple empty blocks' do
        expect(subject[:blocks]).to match_array([
          { type: 'provider', name: 'thingy', arguments: [{ name: 'names', values: [] }] },
        ])
      end
    end

    context 'when parsing multiple multi-line blocks with one assignment to a multi-line array' do
      let(:hcl) do
        <<~HCL
          provider "thingy" {
            names = [
              "blah"
            ]
          }

          provider "other.thingy" {
          }
        HCL
      end

      it 'parses multiple empty blocks' do
        expect(subject[:blocks]).to match_array([
          { type: 'provider', name: 'thingy', arguments: [{ name: 'names', values: [{ value: 'blah' }] }] },
          { type: 'provider', name: 'other.thingy', arguments: [] },
        ])
      end
    end
  end
end
