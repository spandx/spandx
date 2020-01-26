# frozen_string_literal: true

RSpec.describe Spandx::Content do
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

  describe '#wordset' do
    it 'creates the wordset' do
      wordset = Set.new(
        %w[
          the made up license this provided as is please respect
          contributors' wishes when implementing license's software
        ]
      )
      expect(subject.tokens).to eql(wordset)
    end
  end
end
