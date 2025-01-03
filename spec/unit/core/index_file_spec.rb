# frozen_string_literal: true

RSpec.describe Spandx::Core::IndexFile do
  subject { described_class.new(data_file) }

  describe '#search' do
    let(:data_file) { Spandx::Core::DataFile.new(tmp_file.path) }
    let(:tmp_file) { Tempfile.new }

    before do
      data_file.insert('activemodel', '6.0.2.2', ['Apache-2.0'])
      data_file.insert('spandx', '0.1.0', ['MIT'])
      data_file.insert('zlib', '1.1.0', ['0BSD'])

      subject.update!
    end

    after do
      tmp_file.unlink
    end

    specify do
      result = subject.search { |row| 'activemodel-6.0.2.2' <=> "#{row[0]}-#{row[1]}" }
      expect(result).to eql(['activemodel', '6.0.2.2', 'Apache-2.0'])
    end

    specify do
      result = subject.search { |row| 'spandx-0.1.0' <=> "#{row[0]}-#{row[1]}" }
      expect(result).to eql(['spandx', '0.1.0', 'MIT'])
    end

    specify do
      result = subject.search { |row| 'zlib-1.1.0' <=> "#{row[0]}-#{row[1]}" }
      expect(result).to eql(['zlib', '1.1.0', '0BSD'])
    end
  end

  describe '#update!' do
    let(:data_file) { Spandx::Core::DataFile.new(path) }
    let(:path) { File.expand_path(File.join(Dir.home, '.local', 'share', 'spandx', 'cache', '.index', '00', 'nuget')) }

    before do
      subject.update!
    end

    it 'rebuilds the index correctly' do
      data_file.each do |item|
        expect(item).not_to be_nil
      end
    end

    specify { expect(data_file.count).to be > 1_000 }
  end
end
