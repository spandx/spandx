# frozen_string_literal: true

RSpec.describe Spandx::Ruby::Gateway do
  subject { described_class.new }

  # One request per gem, not one per version: the compact index lists 1,783,119
  # version rows across ~202k gems.
  describe '#resolve' do
    before do
      stub_request(:get, 'https://rubygems.org/api/v1/versions/spandx.json').to_return(
        status: 200,
        body: JSON.generate(
          [
            { 'number' => '0.2.0', 'licenses' => ['MIT'] },
            { 'number' => '0.1.0', 'licenses' => ['MIT'] },
          ]
        )
      )
    end

    it 'returns every version from a single request' do
      expect(subject.resolve(subject, 'spandx')).to eql(
        [['spandx', '0.2.0', ['MIT']], ['spandx', '0.1.0', ['MIT']]]
      )
    end

    context 'when a version has no licenses' do
      before do
        stub_request(:get, 'https://rubygems.org/api/v1/versions/spandx.json')
          .to_return(status: 200, body: JSON.generate([{ 'number' => '0.1.0', 'licenses' => nil }]))
      end

      it 'returns it with none' do
        expect(subject.resolve(subject, 'spandx')).to eql([['spandx', '0.1.0', []]])
      end
    end

    context 'when the gem is unknown' do
      before do
        stub_request(:get, 'https://rubygems.org/api/v1/versions/spandx.json').to_return(status: 404)
      end

      it 'returns nothing' do
        expect(subject.resolve(subject, 'spandx')).to be_empty
      end
    end
  end

  describe '#each_package' do
    let(:names) { [] }

    before do
      VCR.use_cassette('index.rubygems.org/versions') do
        subject.each_package { |name| names << name }
      end
    end

    it 'yields gem names, not versions' do
      expect(names.first).to eql('-')
    end

    # The compact index appends a line per publish, so a gem recurs.
    it 'yields each name exactly once' do
      expect(names.uniq.count).to be(names.count)
    end

    it 'yields far fewer names than the 1,110,304 version rows it reads' do
      expect(names.count).to be < 1_110_304
    end
  end
end
