# frozen_string_literal: true

RSpec.describe Spandx::Core::PathTraversal do
  let(:result) do
    [].tap do |items|
      subject.each do |item|
        items << item.to_s
      end
    end
  end

  around do |example|
    within_tmp_dir do |directory|
      directory.join('./00/01/02/03/04').mkpath
      directory.join('./00/01/02/03/04/.04').write('04')
      directory.join('./00/01/02/03/04/file.04').write('04')
      directory.join('./00/01/02/03/file.03').write('03')
      directory.join('./00/01/02/file.02').write('02')
      directory.join('./00/01/file.01').write('01')
      directory.join('./00/file.00').write('00')
      directory.join('./file').write('.')

      example.run
    end
  end

  describe '#each' do
    context 'when traversing a directory non-recursively' do
      subject { described_class.new(Pathname.pwd, recursive: false) }

      specify do
        expect(result.map { |x| Pathname.new(x).basename.to_s }).to match_array(['file'])
      end
    end

    context 'when traversing a directory recursively' do
      subject { described_class.new(Pathname.pwd, recursive: true) }

      specify do
        expect(result.map { |x| Pathname.new(x).basename.to_s }).to match_array([
          'file', 'file.00', 'file.01', 'file.02', 'file.03', 'file.04', '.04'
        ])
      end
    end

    context 'when traversing a file non-recursively' do
      subject { described_class.new(path, recursive: false) }

      let(:path) { Pathname.pwd.join('./file') }

      specify do
        expect(result.map { |x| Pathname.new(x).basename.to_s }).to match_array(['file'])
      end
    end

    context 'when traversing a file recursively' do
      subject { described_class.new(path, recursive: true) }

      let(:path) { Pathname.pwd.join('./file') }

      specify do
        expect(result.map { |x| Pathname.new(x).basename.to_s }).to match_array(['file'])
      end
    end
  end
end
