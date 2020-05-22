# frozen_string_literal: true

RSpec.describe Spandx::Core::Report do
  def build(name, version, path)
    Spandx::Core::Dependency.new(name: name, version: version, path: path)
  end

  describe '#dependencies' do
    before do
      subject.add(build('spandx', '0.1.0', Pathname('./Gemfile.lock')))
      subject.add(build('spandx', '0.1.0', Pathname('./Gemfile.lock')))
    end

    specify { expect(subject.dependencies.count).to be(1) }
    specify { expect(subject.dependencies.to_a).to eql([build('spandx', '0.1.0', Pathname('./Gemfile.lock'))]) }
  end
end
