# frozen_string_literal: true

RSpec.describe Spandx::Spdx::Expression do
  subject(:parser) { described_class.new }

  describe '#parse' do
    subject { parser.parse_with_debug(expression) }

    context 'when parsing `MIT`' do
      let(:expression) { 'MIT' }

      specify { expect(subject).to match_array([{ left: 'MIT' }]) }
    end

    context 'when parsing `GPL-1.0+`' do
      let(:expression) { 'GPL-1.0+' }

      specify { expect(subject).to match_array([{ left: 'GPL-1.0+' }]) }
    end

    context 'when parsing `(MIT)`' do
      let(:expression) { '(MIT)' }

      specify { expect(subject).to match_array([{ left: 'MIT' }]) }
    end

    context 'when parsing `MIT or GPLv3`' do
      let(:expression) { 'MIT or GPLv3' }

      specify { expect(subject).to match_array([{ left: 'MIT', op: 'or', right: 'GPLv3' }]) }
    end

    context 'when parsing `(0BSD OR MIT)`' do
      let(:expression) { '(0BSD OR MIT)' }

      specify { expect(subject).to match_array([{ left: '0BSD', op: 'OR', right: 'MIT' }]) }
    end

    context 'when parsing `(BSD-2-Clause OR MIT OR Apache-2.0)`' do
      let(:expression) { '(BSD-2-Clause OR MIT OR Apache-2.0)' }

      specify { expect(subject).to match_array([{ left: 'BSD-2-Clause', op: 'OR', right: { left: 'MIT', op: 'OR', right: 'Apache-2.0' } }]) }
    end

    context 'when parsing `(BSD-3-Clause OR GPL-2.0)`' do
      let(:expression) { '(BSD-3-Clause OR GPL-2.0)' }

      specify { expect(subject).to match_array([{ left: 'BSD-3-Clause', op: 'OR', right: 'GPL-2.0' }]) }
    end

    context 'when parsing `(MIT AND CC-BY-3.0)`' do
      let(:expression) { '(MIT AND CC-BY-3.0)' }

      specify { expect(subject).to match_array([{ left: 'MIT', op: 'AND', right: 'CC-BY-3.0' }]) }
    end

    context 'when parsing `(MIT AND Zlib)`' do
      let(:expression) { '(MIT AND Zlib)' }

      specify { expect(subject).to match_array([{ left: 'MIT', op: 'AND', right: 'Zlib' }]) }
    end

    context 'when parsing `(MIT OR Apache-2.0)`' do
      let(:expression) { '(MIT OR Apache-2.0)' }

      specify { expect(subject).to match_array([{ left: 'MIT', op: 'OR', right: 'Apache-2.0' }]) }
    end

    context 'when parsing `(MIT OR CC0-1.0)`' do
      let(:expression) { '(MIT OR CC0-1.0)' }

      specify { expect(subject).to match_array([{ left: 'MIT', op: 'OR', right: 'CC0-1.0' }]) }
    end

    context 'when parsing `(MIT OR GPL-3.0)`' do
      let(:expression) { '(MIT OR GPL-3.0)' }

      specify { expect(subject).to match_array([{ left: 'MIT', op: 'OR', right: 'GPL-3.0' }]) }
    end

    context 'when parsing `(WTFPL OR MIT)`' do
      let(:expression) { '(WTFPL OR MIT)' }

      specify { expect(subject).to match_array([{ left: 'WTFPL', op: 'OR', right: 'MIT' }]) }
    end

    context 'when parsing `BSD-3-Clause OR MIT`' do
      let(:expression) { 'BSD-3-Clause OR MIT' }

      specify { expect(subject).to match_array([{ left: 'BSD-3-Clause', op: 'OR', right: 'MIT' }]) }
    end

    context 'when parsing `(GPL-2.0+ WITH Bison-Exception)`' do
      let(:expression) { '(GPL-2.0+ WITH Bison-Exception)' }

      specify { expect(subject).to match_array([{ left: 'GPL-2.0+', op: 'WITH', right: 'Bison-Exception' }]) }
    end

    [
      'GPL-1.0+',
      'EPL-1.0+',
      'AGPL-3.0+',
      'Python-2.0+',
      '(MPL-1.1 OR GPL-2.0+ OR LGPL-2.1+)',
      '(LGPL-2.0+ AND AML)',
      '(GPL-2.0+ AND APSL-1.1)',
      '(GPL-2.0 AND MIT AND BSD-3-Clause)',
      'LicenseRef-AGPL3-WITH-Exception',
      'LicenseRef-GPL-2.0PlusGhostscriptException',
      'LicenseRef-Nokia-Qt-LGPL-Exception',
      '(GPL-2.0 OR GPL-3.0 OR LicenseRef-Riverbank)',
      'LicenseRef-TMake',
      '(LGPL-2.1 OR LGPL-3.0 OR LicenseRef-KDE-Accepted)',
      '(LGPL-2.0 AND BSD-3-Clause AND MIT and LicenseRef-1 AND LicenseRef-2 AND LicenseRef-3 AND LicenseRef-4 AND LicenseRef-5 AND LicenseRef-6)',
      '(GPL-2.0+ WITH Bison-Exception)',
      '(GPL-3.0+ WITH Bison-Exception)',
    ].each do |raw|
      context "when parsing `#{raw}`" do
        let(:expression) { raw }

        specify { expect(subject).to be_truthy }
      end
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

  describe '#with_expression' do
    subject { described_class.new.with_expression }

    specify { expect(subject).to parse('GPL-2.0+ WITH Bison-Exception') }
    specify { expect(subject).to parse('GPL-3.0+ WITH Bison-Exception') }

    [
      '389-exception',
      'Autoconf-exception-2.0',
      'Autoconf-exception-3.0',
      'Bison-exception-2.2',
      'Classpath-exception-2.0',
      'CLISP-exception-2.0',
      'DigiRule-FOSS-exception',
      'eCos-exception-2.0',
      'Fawkes-Runtime-exception',
      'FLTK-exception',
      'Font-exception-2.0',
      'freertos-exception-2.0',
      'GCC-exception-2.0',
      'GCC-exception-3.1',
      'gnu-javamail-exception',
      'i2p-gpl-java-exception',
      'Libtool-exception',
      'LZMA-exception',
      'mif-exception',
      'Nokia-Qt-exception-1.1',
      'OCCT-exception-1.0',
      'openvpn-openssl-exception',
      'Qwt-exception-1.0',
      'u-boot-exception-2.0',
      'WxWindows-exception-3.1',
    ].each do |exception|
      specify { expect(subject.parse_with_debug("GPL-3.0+ WITH #{exception}")).to be_truthy }
    end
  end

  describe '#binary_expression' do
    subject { described_class.new.binary_expression }

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
