# frozen_string_literal: true

RSpec.describe Spandx::Commands::Scan do
  subject { described_class.new(lockfile, options) }

  let(:output) { StringIO.new }
  let(:lockfile) { nil }
  let(:options) { {} }

  it 'executes `scan` command successfully' do
    subject.execute(output: output)

    expect(output.string).to eq("OK\n")
  end

  context "when scanning Gemfile.lock" do
    let(:lockfile) { fixture_file('bundler/Gemfile-single.lock') }

    it 'produces the proper report' do
      subject.execute(output: output)

      expect(output.string).to eq("OK\n")
    end
  end
end
