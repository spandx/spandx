# frozen_string_literal: true

RSpec.describe Spandx::Js::YarnLock do
  subject { described_class.new(fixture_file('js/yarn.lock')) }

  describe "#each" do
    let(:items) { [] }

    before do
      subject.each do |item|
        items << item
      end
    end

    specify { expect(items).not_to be_empty }
    specify { expect(items.map { |x| x['name'] }).to include('@types/node') }
    specify { expect(items.map { |x| x['name'] }).to include('@babel/core') }
  end
end
