# frozen_string_literal: true

RSpec.describe Spandx::Os::Parsers::Dpkg do
  describe '#parse' do
    subject { described_class.new.parse(path) }

    let(:path) { fixture_file('os/var/lib/dpkg/status') }

    def build(name, version, path)
      Spandx::Core::Dependency.new(name: name, version: version, path: path)
    end

    specify { expect(subject).to include(build('adduser', '3.118', path)) }
    specify { expect(subject).to include(build('apt', '1.8.2.1', path)) }
    specify { expect(subject).to include(build('base-files', '10.3+deb10u6', path)) }
    specify { expect(subject).to include(build('base-passwd', '3.5.46', path)) }
    specify { expect(subject).to include(build('bash', '5.0-4', path)) }
    specify { expect(subject).to include(build('bsdutils', '1:2.33.1-0.1', path)) }
    specify { expect(subject).to include(build('coreutils', '8.30-3', path)) }
    specify { expect(subject).to include(build('dash', '0.5.10.2-5', path)) }
    specify { expect(subject).to include(build('debconf', '1.5.71', path)) }
    specify { expect(subject).to include(build('debian-archive-keyring', '2019.1', path)) }
    specify { expect(subject).to include(build('debianutils', '4.8.6.1', path)) }
    specify { expect(subject).to include(build('diffutils', '1:3.7-3', path)) }
    specify { expect(subject).to include(build('dpkg', '1.19.7', path)) }
    specify { expect(subject).to include(build('e2fsprogs', '1.44.5-1+deb10u3', path)) }
    specify { expect(subject).to include(build('fdisk', '2.33.1-0.1', path)) }
    specify { expect(subject).to include(build('findutils', '4.6.0+git+20190209-2', path)) }
    specify { expect(subject).to include(build('gcc-8-base', '8.3.0-6', path)) }
    specify { expect(subject).to include(build('gpgv', '2.2.12-1+deb10u1', path)) }
    specify { expect(subject).to include(build('grep', '3.3-1', path)) }
    specify { expect(subject).to include(build('gzip', '1.9-3', path)) }
    specify { expect(subject).to include(build('hostname', '3.21', path)) }
    specify { expect(subject).to include(build('init-system-helpers', '1.56+nmu1', path)) }
    specify { expect(subject).to include(build('libacl1', '2.2.53-4', path)) }
    specify { expect(subject).to include(build('libapt-pkg5.0', '1.8.2.1', path)) }
    specify { expect(subject).to include(build('libattr1', '1:2.4.48-4', path)) }
    specify { expect(subject).to include(build('libaudit-common', '1:2.8.4-3', path)) }
    specify { expect(subject).to include(build('libaudit1', '1:2.8.4-3', path)) }
    specify { expect(subject).to include(build('libblkid1', '2.33.1-0.1', path)) }
    specify { expect(subject).to include(build('libbz2-1.0', '1.0.6-9.2~deb10u1', path)) }
    specify { expect(subject).to include(build('libc-bin', '2.28-10', path)) }
    specify { expect(subject).to include(build('libc6', '2.28-10', path)) }
    specify { expect(subject).to include(build('libcap-ng0', '0.7.9-2', path)) }
    specify { expect(subject).to include(build('libcom-err2', '1.44.5-1+deb10u3', path)) }
    specify { expect(subject).to include(build('libdb5.3', '5.3.28+dfsg1-0.5', path)) }
    specify { expect(subject).to include(build('libdebconfclient0', '0.249', path)) }
    specify { expect(subject).to include(build('libext2fs2', '1.44.5-1+deb10u3', path)) }
    specify { expect(subject).to include(build('libfdisk1', '2.33.1-0.1', path)) }
    specify { expect(subject).to include(build('libffi6', '3.2.1-9', path)) }
    specify { expect(subject).to include(build('libgcc1', '1:8.3.0-6', path)) }
    specify { expect(subject).to include(build('libgcrypt20', '1.8.4-5', path)) }
    specify { expect(subject).to include(build('libgmp10', '2:6.1.2+dfsg-4', path)) }
    specify { expect(subject).to include(build('libgnutls30', '3.6.7-4+deb10u5', path)) }
    specify { expect(subject).to include(build('libgpg-error0', '1.35-1', path)) }
    specify { expect(subject).to include(build('libhogweed4', '3.4.1-1', path)) }
    specify { expect(subject).to include(build('libidn2-0', '2.0.5-1+deb10u1', path)) }
    specify { expect(subject).to include(build('liblz4-1', '1.8.3-1', path)) }
    specify { expect(subject).to include(build('liblzma5', '5.2.4-1', path)) }
    specify { expect(subject).to include(build('libmount1', '2.33.1-0.1', path)) }
    specify { expect(subject).to include(build('libncursesw6', '6.1+20181013-2+deb10u2', path)) }
    specify { expect(subject).to include(build('libnettle6', '3.4.1-1', path)) }
    specify { expect(subject).to include(build('libp11-kit0', '0.23.15-2', path)) }
    specify { expect(subject).to include(build('libpam-modules', '1.3.1-5', path)) }
    specify { expect(subject).to include(build('libpam-modules-bin', '1.3.1-5', path)) }
    specify { expect(subject).to include(build('libpam-runtime', '1.3.1-5', path)) }
    specify { expect(subject).to include(build('libpam0g', '1.3.1-5', path)) }
    specify { expect(subject).to include(build('libpcre3', '2:8.39-12', path)) }
    specify { expect(subject).to include(build('libseccomp2', '2.3.3-4', path)) }
    specify { expect(subject).to include(build('libselinux1', '2.8-1+b1', path)) }
    specify { expect(subject).to include(build('libsemanage-common', '2.8-2', path)) }
    specify { expect(subject).to include(build('libsemanage1', '2.8-2', path)) }
    specify { expect(subject).to include(build('libsepol1', '2.8-1', path)) }
    specify { expect(subject).to include(build('libsmartcols1', '2.33.1-0.1', path)) }
    specify { expect(subject).to include(build('libss2', '1.44.5-1+deb10u3', path)) }
    specify { expect(subject).to include(build('libstdc++6', '8.3.0-6', path)) }
    specify { expect(subject).to include(build('libsystemd0', '241-7~deb10u4', path)) }
    specify { expect(subject).to include(build('libtasn1-6', '4.13-3', path)) }
    specify { expect(subject).to include(build('libtinfo6', '6.1+20181013-2+deb10u2', path)) }
    specify { expect(subject).to include(build('libudev1', '241-7~deb10u4', path)) }
    specify { expect(subject).to include(build('libunistring2', '0.9.10-1', path)) }
    specify { expect(subject).to include(build('libuuid1', '2.33.1-0.1', path)) }
    specify { expect(subject).to include(build('libzstd1', '1.3.8+dfsg-3', path)) }
    specify { expect(subject).to include(build('login', '1:4.5-1.1', path)) }
    specify { expect(subject).to include(build('mawk', '1.3.3-17+b3', path)) }
    specify { expect(subject).to include(build('mount', '2.33.1-0.1', path)) }
    specify { expect(subject).to include(build('ncurses-base', '6.1+20181013-2+deb10u2', path)) }
    specify { expect(subject).to include(build('ncurses-bin', '6.1+20181013-2+deb10u2', path)) }
    specify { expect(subject).to include(build('passwd', '1:4.5-1.1', path)) }
    specify { expect(subject).to include(build('perl-base', '5.28.1-6+deb10u1', path)) }
    specify { expect(subject).to include(build('sed', '4.7-1', path)) }
    specify { expect(subject).to include(build('sysvinit-utils', '2.93-8', path)) }
    specify { expect(subject).to include(build('tar', '1.30+dfsg-6', path)) }
    specify { expect(subject).to include(build('tzdata', '2020a-0+deb10u1', path)) }
    specify { expect(subject).to include(build('util-linux', '2.33.1-0.1', path)) }
    specify { expect(subject).to include(build('zlib1g', '1:1.2.11.dfsg-1', path)) }
  end

  describe '#match?' do
    it { is_expected.to be_match(to_path('/var/lib/dpkg/status')) }
    it { is_expected.to be_match(to_path('status')) }
    it { is_expected.to be_match(to_path('./status')) }
    it { is_expected.to be_match(to_path('/root/status')) }
    it { is_expected.not_to be_match(to_path('status.xml')) }
    it { is_expected.not_to be_match(to_path('/root/status.lock')) }
  end
end
