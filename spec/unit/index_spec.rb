# frozen_string_literal: true

RSpec.describe Spandx::Index do
  subject { described_class.new(directory: directory) }

  let(:directory) { Dir.mktmpdir('spandx') }

  after do
    FileUtils.rm_r(directory, force: true, secure: true)
  end

  describe "#read" do
    let(:key) { ['x', 'y', 'z'] }
    let(:data) { SecureRandom.uuid }

    before do
      subject.write(key, data)
    end

    specify { expect(subject.read(key)).to eql(data) }
  end

  describe "#indexed?" do
    let(:key) { ['x', 'y', 'z'] }
    let(:data) { SecureRandom.uuid }

    before do
      subject.write(key, data)
    end

    specify { expect(subject).to be_indexed(key) }
  end
end
