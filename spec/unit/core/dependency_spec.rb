# frozen_string_literal: true

RSpec.describe Spandx::Core::Dependency do
  describe '#licenses' do
    [
      { package_manager: :rubygems, name: 'spandx', version: '0.1.0', expected: ['MIT'] },
    ].each do |item|
      context "#{item[:package_manager]}-#{item[:name]}-#{item[:version]}" do
        subject { described_class.new(package_manager: item[:package_manager], name: item[:name], version: item[:version]) }

        let(:results) do
          VCR.use_cassette("#{item[:package_manager]}-#{item[:name]}-#{item[:version]}") do
            subject.licenses
          end
        end

        it { expect(results.map(&:id)).to match_array(item[:expected]) }
      end
    end
  end

  describe '#managed_by?' do
    subject { described_class.new(package_manager: :nuget, name: 'jive', version: '0.1.0') }

    specify { expect(subject).to be_managed_by(:nuget) }
    specify { expect(subject).to be_managed_by('nuget') }
    specify { expect(subject).not_to be_managed_by('rubygems') }
    specify { expect(subject).not_to be_managed_by(nil) }
    specify { expect(subject).not_to be_managed_by(:rubygems) }
  end
end
