# frozen_string_literal: true

RSpec.describe Spandx::Core::Parser do
  subject { described_class }

  describe ".for" do
    describe "when the `composer.lock` file is empty" do
      let(:empty_file) { fixture_file('empty/composer.lock') }
      let(:result) { subject.for(empty_file) }

      specify { expect(result).to be(Spandx::Core::Parser::UNKNOWN) }
    end

    describe "when the `composer.lock` file is discovered" do
      let(:lock_file) { fixture_file('composer/composer.lock') }
      let(:result) { subject.for(lock_file) }

      specify { expect(result).to be_instance_of(Spandx::Php::Parsers::Composer) }
    end
  end
end
