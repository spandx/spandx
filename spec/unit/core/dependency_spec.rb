# frozen_string_literal: true

RSpec.describe Spandx::Core::Dependency do
  subject { described_class.new(name: 'jive', version: '0.1.0', path: path) }

  let(:path) { Pathname.new('Gemfile.lock') }

  def build(name, version, path: 'Gemfile.lock')
    described_class.new(name: name, version: version, path: Pathname.new(path))
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
    specify { expect(build('abc', '0.1.0', path: path).inspect).to eql("#<#{described_class} name=abc version=0.1.0 path=#{path}>") }
  end

  describe '#hash' do
    specify { expect(build('abc', '0.1.0').hash).to eql(build('abc', '0.1.0').hash) }
    specify { expect(build('abc', '0.1.0', path: Pathname.new('Gemfile.lock')).hash).to eql(build('abc', '0.1.0', path: './Gemfile.lock').hash) }
    specify { expect(build('abc', '0.1.0').hash).not_to eql(build('abc', '0.0.0').hash) }
    specify { expect(build('xyz', '0.1.0').hash).not_to eql(build('abc', '0.1.0').hash) }
  end
end
