# frozen_string_literal: true

RSpec.describe Spandx::Content do
  subject { described_class.new(content) }

  let(:content) do
    license_file('MIT')
      .gsub('<year>', Time.now.year.to_s)
      .gsub('<copyright holders>', 'Tsuyoshi Garrett')
  end

  def text(text)
    described_class.new(text)
  end

  describe '#similar?' do
    let(:mit) { described_class.new(license_file('MIT')) }
    let(:lgpl) { described_class.new(license_file('LGPL-2.0-only')) }

    [
      :dice_coefficient,
      :jaro_winkler,
      #:levenshtein,
    ].each do |algorithm|
      specify { expect(subject).to be_similar(mit, algorithm: algorithm) }
      specify { expect(subject).not_to be_similar(lgpl, algorithm: algorithm) }
      specify { expect(subject).to be_similar(subject, algorithm: algorithm) }
      specify { expect(text('hello world')).to be_similar(text('hello world'), algorithm: algorithm) }
      specify { expect(text('hello world')).not_to be_similar(text('goodbye world'), algorithm: algorithm) }
      specify { expect(text('hello world')).not_to be_similar(text('goodbye universe'), algorithm: algorithm) }
      specify { expect(text('a b c')).not_to be_similar(text('b c d'), algorithm: algorithm) }
    end

  end

  describe '#similarity_score' do
    specify { expect(text('hello world').similarity_score(text('hello world'))).to be(100.0) }
    specify { expect(text('hello world').similarity_score(text('goodbye world'))).to be(50.0) }
    specify { expect(text('hello world').similarity_score(text('goodbye universe'))).to be(0.0) }
    specify { expect(text('a b c').similarity_score(text('b c d'))).to be(66.66666666666666) }
  end
end
