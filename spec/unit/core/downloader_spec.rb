# frozen_string_literal: true

RSpec.describe Spandx::Core::Downloader do
  subject { described_class.new }

  let(:path) { File.join(Dir.tmpdir, "downloader-#{SecureRandom.uuid}") }
  let(:url) { 'https://example.com/index.gz' }

  after { FileUtils.rm_f(path) }

  def download(from = url)
    subject.call(URI.parse(from), path, 3)
  end

  it 'writes the body to disk' do
    stub_request(:get, url).to_return(status: 200, body: 'payload')

    download

    expect(File.read(path)).to eql('payload')
  end

  it 'reports that it wrote the file' do
    stub_request(:get, url).to_return(status: 200, body: 'payload')

    expect(download).to be(true)
  end

  it 'follows a redirect' do
    stub_request(:get, url).to_return(status: 302, headers: { 'Location' => 'https://example.com/moved.gz' })
    stub_request(:get, 'https://example.com/moved.gz').to_return(status: 200, body: 'payload')

    download

    expect(File.read(path)).to eql('payload')
  end

  it 'follows a relative redirect' do
    stub_request(:get, url).to_return(status: 302, headers: { 'Location' => '/moved.gz' })
    stub_request(:get, 'https://example.com/moved.gz').to_return(status: 200, body: 'payload')

    download

    expect(File.read(path)).to eql('payload')
  end

  context 'when the response is not a success' do
    before { stub_request(:get, url).to_return(status: 404) }

    it { expect(download).to be(false) }
    it { expect(File.exist?(path)).to be(false) }
  end

  context 'when the uri is not http' do
    it { expect { download('ftp://example.com/index.gz') }.to raise_error(URI::InvalidURIError) }
  end

  # The read timeout that suits an API call would abort a multi-gigabyte index.
  it 'uses a longer read timeout than a regular request' do
    expect(described_class::READ_TIMEOUT).to be > Spandx::Core::Http::READ_TIMEOUT
  end
end
