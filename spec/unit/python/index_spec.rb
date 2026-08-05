# frozen_string_literal: true

RSpec.describe Spandx::Python::Index do
  subject { described_class.new(directory:, concurrency: 2) }

  let(:directory) { Dir.mktmpdir('spandx') }
  let(:cache) { Spandx::Core::Cache.new('pypi', root: directory) }

  after do
    FileUtils.rm_r(directory, force: true, secure: true)
  end

  describe '#update!' do
    before do
      stub_request(:get, 'https://pypi.org/simple/').to_return(
        status: 200,
        body: '<html><body><a href="/simple/six/">six</a></body></html>'
      )
      stub_request(:get, 'https://pypi.org/simple/six/').to_return(
        status: 200,
        body: '<html><body><h1>Links for six</h1>' \
              '<a href="https://files.pythonhosted.org/packages/six-1.13.0.tar.gz">six-1.13.0.tar.gz</a>' \
              '</body></html>'
      )
      stub_request(:get, 'https://pypi.org/pypi/six/1.13.0/json')
        .to_return(status: 200, body: JSON.generate(info: { license: 'MIT' }))

      subject.update!
    end

    specify { expect(cache.licenses_for('six', '1.13.0')).to match_array(['MIT']) }
  end
end
