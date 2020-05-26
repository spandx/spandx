# frozen_string_literal: true

RSpec.describe Spandx::Java::Parsers::Maven do
  describe '#parse' do
    context 'when parsing a simple-pom.xml' do
      subject { described_class.new.parse(fixture_file('maven/simple-pom.xml')) }

      specify { expect(subject[0].name).to eql('junit:junit') }
      specify { expect(subject[0].version).to eql('3.8.1') }
    end

    context 'when parsing an invlid pom.xml' do
      subject { described_class.new.parse(fixture_file('maven/invalid-spec-url-pom.xml')) }

      specify { expect(subject[0].name).to eql('${project.groupId}:model') }
    end
  end

  describe '#match?' do
    it { is_expected.to be_match(to_path('pom.xml')) }
    it { is_expected.to be_match(to_path('/root/pom.xml')) }
    it { is_expected.not_to be_match(to_path('sitemap.xml')) }
    it { is_expected.not_to be_match(to_path('/root/notpom.xml')) }
  end
end
