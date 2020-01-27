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
end
