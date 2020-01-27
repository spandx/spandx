# frozen_string_literal: true

RSpec.describe Spandx::Content::Text do
  subject { described_class.new(content, catalogue) }

  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx.json')) }
  let(:content) do
    license_file('MIT')
      .gsub('<year>', Time.now.year.to_s)
      .gsub('<copyright holders>', 'Tsuyoshi Garrett')
  end

  describe "#similar?" do
    let(:mit) { described_class.new(license_file('MIT'), catalogue) }

    specify { expect(subject.similar?(mit)).to be(true)  }
    specify { expect(subject.similar?(subject)).to be(true) }
  end
end
