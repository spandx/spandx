# frozen_string_literal: true

RSpec.describe Spandx::Spdx::Expression do
  subject { described_class.new }

  describe '#parse' do
    specify { expect(subject).to parse('MIT') }
    specify { expect(subject.parse('MIT').to_s).to eql('MIT') }

    specify { expect(subject.parse_with_debug('MIT or GPLv3')).to be_truthy }
    specify { expect(subject.parse_with_debug('(0BSD OR MIT)')).to be_truthy }
    pending { expect(subject.parse_with_debug('(BSD-2-Clause OR MIT OR Apache-2.0)')).to be_truthy }
    specify { expect(subject.parse_with_debug('(BSD-3-Clause OR GPL-2.0)')).to be_truthy }
    specify { expect(subject.parse_with_debug('(MIT AND CC-BY-3.0)')).to be_truthy }
    specify { expect(subject.parse_with_debug('(MIT AND Zlib)')).to be_truthy }
    specify { expect(subject.parse_with_debug('(MIT OR Apache-2.0)')).to be_truthy }
    specify { expect(subject.parse_with_debug('(MIT OR CC0-1.0)')).to be_truthy }
    specify { expect(subject.parse_with_debug('(MIT OR GPL-3.0)')).to be_truthy }
    specify { expect(subject.parse_with_debug('(WTFPL OR MIT)')).to be_truthy }
    specify { expect(subject.parse_with_debug('BSD-3-Clause OR MIT')).to be_truthy }
  end

  describe '#simple_expression' do
    specify { expect(subject.simple_expression).to parse('MIT') }
    specify { expect(subject.simple_expression).to parse('0BSD') }
    specify { expect(subject.simple_expression).to parse('BSD-3-Clause') }
    specify { expect(subject.simple_expression).to parse('GPLv3') }
  end

  describe '#license_id' do
    specify { expect(subject.license_id).to parse('MIT') }
    specify { expect(subject.license_id).to parse('0BSD') }
  end

  describe '$license_exception_id' do
    specify { expect(subject.license_exception_id).to parse('389-exception') }
  end

  describe '#with_expression' do
  end

  describe '#and_expression' do
    subject { described_class.new.and_expression }

    specify { expect(subject.parse_with_debug('0BSD AND MIT')).to be_truthy }
  end

  describe '#or_expression' do
    subject { described_class.new.or_expression }

    specify { expect(subject.parse_with_debug('0BSD OR MIT')).to be_truthy }
  end

  describe '#compound_expression' do
    subject { described_class.new.compound_expression }

    specify { expect(subject.parse_with_debug('0BSD AND MIT')).to be_truthy }
    specify { expect(subject.parse_with_debug('0BSD OR MIT')).to be_truthy }
    specify { expect(subject.parse_with_debug('(0BSD OR MIT)')).to be_truthy }
  end
end
