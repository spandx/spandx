# frozen_string_literal: true

RSpec.describe Spandx::Guess do
  subject { described_class.new(catalogue) }

  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx.json')) }

  describe '#license_for' do
    needs_investigation = [
      '389-exception',
      'AGPL-1.0',
      'AGPL-1.0-or-later',
      'AGPL-3.0',
      'AGPL-3.0-or-later',
      'Autoconf-exception-2.0',
      'Autoconf-exception-3.0',
      'Bison-exception-2.2',
      'Bootloader-exception',
      'CLISP-exception-2.0',
      'Classpath-exception-2.0',
      'DigiRule-FOSS-exception',
      'FLTK-exception',
      'Fawkes-Runtime-exception',
      'Font-exception-2.0',
      'GCC-exception-2.0',
      'GCC-exception-3.1',
      'GFDL-1.1',
      'GFDL-1.1-or-later',
      'GFDL-1.2',
      'GFDL-1.2-or-later',
      'GFDL-1.3',
      'GFDL-1.3-or-later',
      'GPL-1.0',
      'GPL-1.0+',
      'GPL-1.0-or-later',
      'GPL-2.0',
      'GPL-2.0+',
      'GPL-2.0-or-later',
      'GPL-2.0-with-GCC-exception',
      'GPL-2.0-with-autoconf-exception',
      'GPL-2.0-with-bison-exception',
      'GPL-2.0-with-classpath-exception',
      'GPL-2.0-with-font-exception',
      'GPL-3.0',
      'GPL-3.0+',
      'GPL-3.0-or-later',
      'GPL-3.0-with-GCC-exception',
      'GPL-3.0-with-autoconf-exception',
      'GPL-CC-1.0',
      'LGPL-2.0',
      'LGPL-2.0+',
      'LGPL-2.0-or-later',
      'LGPL-2.1',
      'LGPL-2.1+',
      'LGPL-2.1-or-later',
      'LGPL-3.0',
      'LGPL-3.0+',
      'LGPL-3.0-or-later',
      'LLVM-exception',
      'LZMA-exception',
      'Libtool-exception',
      'Linux-syscall-note',
      'MPL-2.0-no-copyleft-exception',
      'MulanPSL-1.0',
      'Nokia-Qt-exception-1.1',
      'Nunit',
      'OCCT-exception-1.0',
      'OCaml-LGPL-linking-exception',
      'OGL-Canada-2.0',
      'OLDAP-2.2.1',
      'OLDAP-2.3',
      'OpenJDK-assembly-exception-1.0',
      'PHP-3.01',
      'PS-or-PDF-font-exception-20170817',
      'Qt-GPL-exception-1.0',
      'Qt-LGPL-exception-1.1',
      'Qwt-exception-1.0',
      'SSH-OpenSSH',
      'SSH-short',
      'StandardML-NJ',
      'Swift-exception',
      'UCL-1.0',
      'Universal-FOSS-exception-1.0',
      'WxWindows-exception-3.1',
      'eCos-2.0',
      'eCos-exception-2.0',
      'etalab-2.0',
      'freertos-exception-2.0',
      'gnu-javamail-exception',
      'i2p-gpl-java-exception',
      'licenses',
      'mif-exception',
      'openvpn-openssl-exception',
      'u-boot-exception-2.0',
      'wxWindows',
    ]

    Dir['spec/fixtures/spdx/jsonld/*.jsonld'].map { |x| File.basename(x).gsub('.jsonld', '') }.each do |license|
      next if needs_investigation.include?(license)

      context "when finding a match for #{license}" do
        specify { expect(subject.license_for(license_file(license))).to eql(license) }
      end
    end

    needs_investigation.each do |license|
      context "when finding a match for #{license}" do
        pending { expect(subject.license_for(license_file(license))).to eql(license) }
      end
    end

    context "when guessing the spandx license" do
      let(:content) { IO.read('LICENSE.txt') }

      it 'guesses the spandx license using the default algorithm' do
        expect(subject.license_for(content)).to eql('MIT')
      end

      [
        :dice_coefficient,
        :levenshtein
      ].each do |algorithm|
        context algorithm.to_s do
          specify { expect(subject.license_for(content, algorithm: algorithm)).to eql('MIT') }

          specify do
            expect do
              subject.license_for(content, algorithm: algorithm)
            end.to perform_under(0.05).sample(10)
          end
        end
      end
    end
  end
end
