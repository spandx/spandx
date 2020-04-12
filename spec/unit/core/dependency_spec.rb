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
end
