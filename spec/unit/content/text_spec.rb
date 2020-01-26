# frozen_string_literal: true

RSpec.describe Spandx::Content::Text do
  subject { described_class.new(content, catalogue) }

  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx.json')) }

  let(:content) do
    <<-LICENSE.gsub(/^\s*/, '')
  # The MIT License
  =================

  Copyright 2020 Tsuyoshi Garrett
  *************************

  All rights reserved.

  The made
  * * * *
  up  license.

  This license provided 'as is'. Please respect the contributors' wishes when
  implementing the license's "software".
  -----------
    LICENSE
  end

  describe "#similar?" do
    let(:mit) { described_class.new(license_file('MIT'), catalogue) }

    specify { expect(subject.similar?(mit)).to be_within(1).of(11) }
    specify { expect(subject.similar?(subject)).to be(100.0) }
  end
end
