# frozen_string_literal: true

RSpec.describe Spandx::Php::Parsers::Composer do
  subject { described_class.new(catalogue: catalogue) }

  let(:catalogue) { Spandx::Spdx::Catalogue.from_file(fixture_file('spdx/json/licenses.json')) }

  describe '#parse small lock file' do
    let(:lockfile) { fixture_file('composer/composer.lock') }
    let(:result) { subject.parse(lockfile) }

    expected_array = ['phpdocumentor/reflection-common@2.0.0',
                      'phpdocumentor/type-resolver@1.0.1',
                      'symfony/polyfill-ctype@v1.14.0',
                      'webmozart/assert@1.7.0',
                      'doctrine/instantiator@1.3.0',
                      'hamcrest/hamcrest-php@v2.0.0',
                      'mockery/mockery@1.3.1']

    specify { expect(result.map { |x| "#{x.name}@#{x.version}" }) .to match_array(expected_array) }

    specify { expect(result.map(&:licenses).map(&:first).compact.map(&:id).uniq).to match_array(['MIT', 'BSD-3-Clause']) }
  end
end
