# frozen_string_literal: true

RSpec.describe Spandx::Core::Dependency do
  subject { described_class.new(name: 'jive', version: '0.1.0', path:) }

  let(:path) { Pathname.new('Gemfile.lock') }

  def build(name, version, path: 'Gemfile.lock')
    described_class.new(name:, version:, path: Pathname.new(path))
  end

  describe '#licenses' do
    specify { expect(subject.licenses).to be_empty }
  end

  describe '<=>' do
    specify { expect(build('abc', '0.1.0') <=> build('bcd', '0.1.0')).to be < 0 }
    specify { expect(build('abc', '0.1.0', path: './CHANGELOG.md') <=> build('bcd', '0.1.0', path: 'Gemfile.lock')).to be < 0 }
    specify { expect(build('Abc', '0.1.0') <=> build('acd', '0.1.0')).to be < 0 }
    specify { expect(build('spandx', '1.0.0') <=> build('spandx', '2.0.0')).to be < 0 }
    specify { expect(build('spandx', '1.0.0') <=> build('spandx', nil)).to be < 0 }
    specify { expect(build('spandx', '1.0.0') <=> build(nil, '1.0.0')).to be > 0 }
    specify { expect(build('spandx', '1.0.0') <=> nil).to be > 0 }
  end

  describe '#eql?' do
    specify { expect(build('abc', '0.1.0', path: './Gemfile.lock')).to eql(build('abc', '0.1.0', path: './Gemfile.lock')) }
    specify { expect(build('abc', '0.1.0', path: './Gemfile.lock')).not_to eql(build('abc', '0.1.0', path: './LICENSE.txt')) }
    specify { expect(build('abc', '0.1.0')).not_to eql(build('abc', '0.2.0')) }
    specify { expect(build('abc', '0.1.0')).not_to eql(build('xyz', '0.1.0')) }
  end

  describe '#inspect' do
    specify { expect(build('abc', '0.1.0', path:).inspect).to eql("#<#{described_class} name=abc version=0.1.0 path=#{path}>") }
  end

  describe '#hash' do
    specify { expect(build('abc', '0.1.0').hash).to eql(build('abc', '0.1.0').hash) }
    specify { expect(build('abc', '0.1.0', path: Pathname.new('Gemfile.lock')).hash).to eql(build('abc', '0.1.0', path: './Gemfile.lock').hash) }
    specify { expect(build('abc', '0.1.0').hash).not_to eql(build('abc', '0.0.0').hash) }
    specify { expect(build('xyz', '0.1.0').hash).not_to eql(build('abc', '0.1.0').hash) }
  end

  describe '#package_manager' do
    specify { expect(build('x', '0.1.0', path: fixture_file('bundler/Gemfile.lock')).package_manager).to eq(:rubygems) }
    specify { expect(build('x', '0.1.0', path: fixture_file('composer/composer.lock')).package_manager).to eq(:composer) }
    specify { expect(build('x', '0.1.0', path: fixture_file('js/npm/package-lock.json')).package_manager).to eq(:npm) }
    specify { expect(build('x', '0.1.0', path: fixture_file('js/yarn.lock')).package_manager).to eq(:yarn) }
    specify { expect(build('x', '0.1.0', path: fixture_file('maven/pom.xml')).package_manager).to eq(:maven) }
    specify { expect(build('x', '0.1.0', path: fixture_file('nuget/empty.sln')).package_manager).to eq(:nuget) }
    specify { expect(build('x', '0.1.0', path: fixture_file('nuget/example.csproj')).package_manager).to eq(:nuget) }
    specify { expect(build('x', '0.1.0', path: fixture_file('nuget/packages.config')).package_manager).to eq(:nuget) }
    specify { expect(build('x', '0.1.0', path: fixture_file('os/lib/apk/db/installed')).package_manager).to eq(:apk) }
    specify { expect(build('x', '0.1.0', path: fixture_file('os/var/lib/dpkg/status')).package_manager).to eq(:dpkg) }
    specify { expect(build('x', '0.1.0', path: fixture_file('pip/Pipfile.lock')).package_manager).to eq(:pypi) }
    specify { expect(build('x/y', '0.1.0', path: fixture_file('terraform/simple/.terraform.lock.hcl')).package_manager).to eq(:terraform) }
  end
end
