# frozen_string_literal: true

RSpec.describe Spandx::Terraform::Parsers::LockFile do
  subject(:parser) { described_class.new }

  describe '#match?' do
    it { is_expected.to be_match(to_path('.terraform.lock.hcl')) }
    it { is_expected.not_to be_match(to_path('main.hcl')) }
    it { is_expected.not_to be_match(to_path('main.tf')) }
  end

  describe '#parse' do
    def build(name, version, path)
      Spandx::Core::Dependency.new(name: name, version: version, path: path)
    end

    context 'when parsing a .terraform.lock.hcl file' do
      subject { parser.parse(path) }

      let(:path) { fixture_file('terraform/simple/.terraform.lock.hcl') }

      specify do
        expect(subject).to match_array([
          build('registry.terraform.io/hashicorp/aws', '3.39.0', path)
        ])
      end
    end
  end
end
