# frozen_string_literal: true

RSpec.describe Spandx::Guess do
  subject { described_class.new(catalogue) }

  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

  describe '#license_for' do
    needs_investigation = Hash[[
      "389-exception",
      "AGPL-1.0-or-later",
      "AGPL-3.0-or-later",
      "Autoconf-exception-2.0",
      "Autoconf-exception-3.0",
      "Bison-exception-2.2",
      "Bootloader-exception",
      "CLISP-exception-2.0",
      "Classpath-exception-2.0",
      "DigiRule-FOSS-exception",
      "FLTK-exception",
      "Fawkes-Runtime-exception",
      "Font-exception-2.0",
      "GCC-exception-2.0",
      "GCC-exception-3.1",
      "GFDL-1.1-or-later",
      "GFDL-1.2-or-later",
      "GFDL-1.3-or-later",
      "GPL-1.0-or-later",
      "GPL-2.0-or-later",
      "GPL-3.0-or-later",
      "GPL-CC-1.0",
      "LGPL-2.0-or-later",
      "LGPL-2.1-or-later",
      "LGPL-3.0-or-later",
      "LLVM-exception",
      "LZMA-exception",
      "Libtool-exception",
      "Linux-syscall-note",
      "MPL-2.0-no-copyleft-exception",
      "Nokia-Qt-exception-1.1",
      "OCCT-exception-1.0",
      "OCaml-LGPL-linking-exception",
      "OLDAP-2.2.1",
      "OLDAP-2.3",
      "OpenJDK-assembly-exception-1.0",
      "PHP-3.01",
      "PS-or-PDF-font-exception-20170817",
      "Qt-GPL-exception-1.0",
      "Qt-LGPL-exception-1.1",
      "Qwt-exception-1.0",
      "Swift-exception",
      "Universal-FOSS-exception-1.0",
      "WxWindows-exception-3.1",
      "eCos-exception-2.0",
      "freertos-exception-2.0",
      "gnu-javamail-exception",
      "i2p-gpl-java-exception",
      "mif-exception",
      "openvpn-openssl-exception",
      "u-boot-exception-2.0",
    ].map { |x| [x, true] }]

    Dir['spec/fixtures/spdx/text/*.txt'].map { |x| File.basename(x).gsub('.txt', '') }.each do |license|
      next if license.start_with?("deprecated") || needs_investigation[license]

      context "when finding a match for #{license}" do
        specify { expect(subject.license_for(license_file(license))).to eql(license) }
      end
    end

    needs_investigation.each do |license|
      context "when finding a match for #{license}" do
        pending { expect(subject.license_for(license_file(license))).to eql(license) }
      end
    end

    context 'when guessing the spandx license' do
      let!(:content) { IO.read('LICENSE.txt') }

      it 'guesses the spandx license using the default algorithm' do
        expect(subject.license_for(content)).to eql('MIT')
      end

      specify { expect(subject.license_for(content, algorithm: :dice_coefficient)).to eql('MIT') }
      specify { expect(subject.license_for(content, algorithm: :levenshtein)).to eql('MIT') }

      specify do
        expect do
          subject.license_for(content, algorithm: :dice_coefficient)
        end.to perform_under(0.05).sample(10)
      end

      pending do
        expect do
          subject.license_for(content, algorithm: :levenshtein)
        end.to perform_under(0.05).sample(10)
      end
    end
  end
end
