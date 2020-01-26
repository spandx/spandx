RSpec.describe Spandx::Content::Stripper do
  subject { described_class.new(catalogue) }
  let(:catalogue) { Spandx::Catalogue.from_file(fixture_file('spdx.json')) }

  describe '#strip' do
    {
      version: "The MIT License\nVersion 1.0\nfoo",
      hrs: "The MIT License\n=====\n-----\n*******\nfoo",
      #markdown_headings: "# The MIT License\n\nfoo",
      whitespace: "The MIT License\n\n   foo  ",
      all_rights_reserved: "Copyright 2016 Tsuyoshi Garrett\n\nfoo",
      urls: "https://example.com\nfoo",
      developed_by: "Developed By: Tsuyoshi Garrett\n\nFoo",
      borders: '*   Foo    *',
      title: "The MIT License\nfoo",
      copyright: "The MIT License\nCopyright 2018 Tsuyoshi Garrett\nFoo",
      end_of_terms: "Foo\nend of terms and conditions\nbar",
      block_markup: '> Foo',
      #link_markup: '[Foo](http://exmaple.com)',
      comment_markup: "/*\n* The MIT License\n* Foo\n*/",
      copyright_title: "Copyright 2019 Tsuyoshi Garrett\nMIT License\nFoo"
    }.each do |field, content|
      context "#strip #{field}" do
        specify { expect(subject.strip(content)).to eql('foo') }
      end
    end
  end
end
