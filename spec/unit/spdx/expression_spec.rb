# frozen_string_literal: true

RSpec.describe Spandx::Spdx::Expression do
  subject { described_class.new }

  describe '#parse' do
    subject { described_class.new.parse_with_debug(expression) }

    context 'parsing `MIT`' do
      let(:expression) { 'MIT' }

      specify { expect(subject).to be_truthy }
      specify { puts subject.inspect }
    end

    context 'parsing `(MIT)`' do
      let(:expression) { '(MIT)' }

      specify { expect(subject).to be_truthy }
      specify { puts subject.inspect }
    end

    context 'parsing `MIT or GPLv3`' do
      let(:expression) { 'MIT or GPLv3' }

      specify { expect(subject).to be_truthy }
      specify { puts subject.inspect }
    end

    context 'parsing `(0BSD OR MIT)`' do
      let(:expression) { '(0BSD OR MIT)' }

      specify { expect(subject).to be_truthy }
      specify { puts subject.inspect }
    end

    context 'parsing `(BSD-2-Clause OR MIT OR Apache-2.0)`' do
      let(:expression) { '(BSD-2-Clause OR MIT OR Apache-2.0)' }

      specify { expect(subject).to be_truthy }
      #specify { puts subject.inspect }
    end

    context 'parsing `(BSD-3-Clause OR GPL-2.0)`' do
      let(:expression) { '(BSD-3-Clause OR GPL-2.0)' }

      specify { expect(subject).to be_truthy }
      specify { puts subject.inspect }
    end

    context 'parsing `(MIT AND CC-BY-3.0)`' do
      let(:expression) { '(MIT AND CC-BY-3.0)' }

      specify { expect(subject).to be_truthy }
      specify { puts subject.inspect }
    end

    context 'parsing `(MIT AND Zlib)`' do
      let(:expression) { '(MIT AND Zlib)' }

      specify { expect(subject).to be_truthy }
      specify { puts subject.inspect }
    end

    context 'parsing `(MIT OR Apache-2.0)`' do
      let(:expression) { '(MIT OR Apache-2.0)' }

      specify { expect(subject).to be_truthy }
      specify { puts subject.inspect }
    end

    context 'parsing `(MIT OR CC0-1.0)`' do
      let(:expression) { '(MIT OR CC0-1.0)' }

      specify { expect(subject).to be_truthy }
      specify { puts subject.inspect }
    end

    context 'parsing `(MIT OR GPL-3.0)`' do
      let(:expression) { '(MIT OR GPL-3.0)' }

      specify { expect(subject).to be_truthy }
      specify { puts subject.inspect }
    end

    context 'parsing `(WTFPL OR MIT)`' do
      let(:expression) { '(WTFPL OR MIT)' }

      specify { expect(subject).to be_truthy }
      specify { puts subject.inspect }
    end

    context 'parsing `BSD-3-Clause OR MIT`' do
      let(:expression) { 'BSD-3-Clause OR MIT' }

      specify { expect(subject).to be_truthy }
      specify { puts subject.inspect }
    end
  end

  describe '#simple_expression' do
    subject { described_class.new.simple_expression }

    specify { expect(subject).to parse('MIT') }
    specify { expect(subject).to parse('0BSD') }
    specify { expect(subject).to parse('BSD-3-Clause') }
    specify { expect(subject).to parse('GPLv3') }
  end

  describe '#license_id' do
    subject { described_class.new.license_id }

    specify { expect(subject).to parse('MIT') }
    specify { expect(subject).to parse('0BSD') }
    specify { expect(subject).to parse('BSD-3-Clause') }
  end

  describe '#license_exception_id' do
    subject { described_class.new.license_exception_id }

    specify { expect(subject).to parse('389-exception') }
  end

  describe '#with_expression'

  describe '#op_expression' do
    subject { described_class.new.op_expression }

    specify { expect(subject.parse_with_debug('0BSD or MIT')).to be_truthy }
    specify { expect(subject.parse_with_debug('0BSD OR MIT')).to be_truthy }
    specify { expect(subject.parse_with_debug('0BSD and MIT')).to be_truthy }
    specify { expect(subject.parse_with_debug('0BSD AND MIT')).to be_truthy }
  end

  describe '#compound_expression' do
    subject { described_class.new.compound_expression }

    specify { expect(subject.parse_with_debug('0BSD AND MIT')).to be_truthy }
    specify { expect(subject.parse_with_debug('0BSD OR MIT')).to be_truthy }
    specify { expect(subject.parse_with_debug('(0BSD OR MIT)')).to be_truthy }
  end
end
