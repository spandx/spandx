# frozen_string_literal: true

RSpec.describe Spandx::Os::Parsers::Apk do
  describe '#parse' do
    subject { described_class.new.parse(path) }

    let(:path) { fixture_file('os/apk/db/installed') }

    def build(name, version, path)
      Spandx::Core::Dependency.new(name: name, version: version, path: path)
    end

    specify { expect(subject).to include(build('alpine-baselayout', '3.2.0-r7', path)) }
    specify { expect(subject).to include(build('alpine-keys', '2.2-r0', path)) }
    specify { expect(subject).to include(build('apk-tools', '2.10.5-r1', path)) }
    specify { expect(subject).to include(build('busybox', '1.31.1-r19', path)) }
    specify { expect(subject).to include(build('ca-certificates', '20191127-r4', path)) }
    specify { expect(subject).to include(build('ca-certificates-bundle', '20191127-r4', path)) }
    specify { expect(subject).to include(build('expat', '2.2.9-r1', path)) }
    specify { expect(subject).to include(build('git', '2.26.2-r0', path)) }
    specify { expect(subject).to include(build('libc-utils', '0.7.2-r3', path)) }
    specify { expect(subject).to include(build('libcrypto1.1', '1.1.1g-r0', path)) }
    specify { expect(subject).to include(build('libcurl', '7.69.1-r1', path)) }
    specify { expect(subject).to include(build('libssl1.1', '1.1.1g-r0', path)) }
    specify { expect(subject).to include(build('libtls-standalone', '2.9.1-r1', path)) }
    specify { expect(subject).to include(build('musl', '1.1.24-r9', path)) }
    specify { expect(subject).to include(build('musl-utils', '1.1.24-r9', path)) }
    specify { expect(subject).to include(build('nghttp2-libs', '1.41.0-r0', path)) }
    specify { expect(subject).to include(build('pcre2', '10.35-r0', path)) }
    specify { expect(subject).to include(build('scanelf', '1.2.6-r0', path)) }
    specify { expect(subject).to include(build('ssl_client', '1.31.1-r19', path)) }
    specify { expect(subject).to include(build('zlib', '1.2.11-r3', path)) }
  end

  describe '#match?' do
    it { is_expected.to be_match(to_path('/lib/apk/db/installed')) }
    it { is_expected.to be_match(to_path('installed')) }
    it { is_expected.to be_match(to_path('./installed')) }
    it { is_expected.to be_match(to_path('/root/installed')) }
    it { is_expected.not_to be_match(to_path('installed.xml')) }
    it { is_expected.not_to be_match(to_path('/root/installed.lock')) }
  end
end
