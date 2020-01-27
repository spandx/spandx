# frozen_string_literal: true

RSpec.describe Spandx::Content::Text do
  subject { described_class.new(content) }

  let(:content) do
    license_file('MIT')
      .gsub('<year>', Time.now.year.to_s)
      .gsub('<copyright holders>', 'Tsuyoshi Garrett')
  end

  describe "#similar?" do
    let(:mit) { described_class.new(license_file('MIT')) }
    let(:lgpl) { described_class.new(license_file('LGPL-2.0')) }

    specify { expect(subject.similar?(mit)).to be(true)  }
    specify { expect(subject.similar?(lgpl)).to be(false)  }
    specify { expect(subject.similar?(subject)).to be(true) }
  end

  describe "#dice_coefficient" do
    def text(text)
      described_class.new(text)
    end

    specify do
      expect(text("hello world").dice_coefficient(text("hello world"))).to eql(100.0)
    end

    specify do
      expect(text("hello world").dice_coefficient(text("goodbye world"))).to eql(50.0)
    end

    specify do
      expect(text("hello world").dice_coefficient(text("goodbye universe"))).to eql(0.0)
    end

    specify do
      expect(text("a b c").dice_coefficient(text("b c d"))).to eql(66.66666666666666)
    end
  end
end
