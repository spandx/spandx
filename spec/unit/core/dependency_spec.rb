# frozen_string_literal: true

RSpec.describe Spandx::Core::Dependency do
  subject { described_class.new(package_manager: :nuget, name: 'jive', version: '0.1.0') }

  describe '#licenses' do
    specify { expect(subject.licenses).to be_empty }
  end

  describe '#managed_by?' do
    specify { expect(subject).to be_managed_by(:nuget) }
    specify { expect(subject).to be_managed_by('nuget') }
    specify { expect(subject).not_to be_managed_by('rubygems') }
    specify { expect(subject).not_to be_managed_by(nil) }
    specify { expect(subject).not_to be_managed_by(:rubygems) }
  end

  describe '<=>' do
    def build(name, version)
      described_class.new(package_manager: :rubygems, name: name, version: version)
    end

    specify { expect(build('abc', '0.1.0') <=> build('bcd', '0.1.0')).to be < 0 }
    specify { expect(build('Abc', '0.1.0') <=> build('acd', '0.1.0')).to be < 0 }
    specify { expect(build('spandx', '1.0.0') <=> build('spandx', '2.0.0')).to be < 0 }
    specify { expect(build('spandx', '1.0.0') <=> build('spandx', nil)).to be > 0 }
    specify { expect(build('spandx', '1.0.0') <=> build(nil, '1.0.0')).to be > 0 }
    specify { expect(build('spandx', '1.0.0') <=> nil).to be > 0 }
  end
end
