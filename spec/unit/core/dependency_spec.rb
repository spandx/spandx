# frozen_string_literal: true

RSpec.describe Spandx::Core::Dependency do
  describe "#licenses" do
    [
      { package_manager: :maven, name: 'junit:junit', version: '3.8.1', expected: ['CPL-1.0'] },
      { package_manager: :npm, name: 'accepts', version: '1.3.7', expected: ['MIT'] },
      { package_manager: :npm, name: 'array-flatten', version: '1.1.1', expected: ['MIT'] },
      { package_manager: :npm, name: 'body-parser', version: '1.19.0', expected: ['MIT'] },
      { package_manager: :npm, name: 'bytes', version: '3.1.0', expected: ['MIT'] },
      { package_manager: :npm, name: 'content-disposition', version: '0.5.3', expected: ['MIT'] },
      { package_manager: :npm, name: 'content-type', version: '1.0.4', expected: ['MIT'] },
      { package_manager: :npm, name: 'cookie', version: '0.4.0', expected: ['MIT'] },
      { package_manager: :npm, name: 'cookie-signature', version: '1.0.6', expected: ['MIT'] },
      { package_manager: :npm, name: 'debug', version: '2.6.9', expected: ['MIT'] },
      { package_manager: :npm, name: 'depd', version: '1.1.2', expected: ['MIT'] },
      { package_manager: :npm, name: 'destroy', version: '1.0.4', expected: ['MIT'] },
      { package_manager: :npm, name: 'ee-first', version: '1.1.1', expected: ['MIT'] },
      { package_manager: :npm, name: 'encodeurl', version: '1.0.2', expected: ['MIT'] },
      { package_manager: :npm, name: 'escape-html', version: '1.0.3', expected: ['MIT'] },
      { package_manager: :npm, name: 'etag', version: '1.8.1', expected: ['MIT'] },
      { package_manager: :npm, name: 'express', version: '4.17.1', expected: ['MIT'] },
      { package_manager: :npm, name: 'finalhandler', version: '1.1.2', expected: ['MIT'] },
      { package_manager: :npm, name: 'forwarded', version: '0.1.2', expected: ['MIT'] },
      { package_manager: :npm, name: 'fresh', version: '0.5.2', expected: ['MIT'] },
      { package_manager: :npm, name: 'http-errors', version: '1.7.2', expected: ['MIT'] },
      { package_manager: :npm, name: 'iconv-lite', version: '0.4.24', expected: ['MIT'] },
      { package_manager: :npm, name: 'inherits', version: '2.0.3', expected: ['ISC'] },
      { package_manager: :npm, name: 'ipaddr.js', version: '1.9.1', expected: ['MIT'] },
      { package_manager: :npm, name: 'jquery', version: '3.4.0', expected: ['MIT'] },
      { package_manager: :npm, name: 'media-typer', version: '0.3.0', expected: ['MIT'] },
      { package_manager: :npm, name: 'merge-descriptors', version: '1.0.1', expected: ['MIT'] },
      { package_manager: :npm, name: 'methods', version: '1.1.2', expected: ['MIT'] },
      { package_manager: :npm, name: 'mime', version: '1.6.0', expected: ['MIT'] },
      { package_manager: :npm, name: 'mime-db', version: '1.43.0', expected: ['MIT'] },
      { package_manager: :npm, name: 'mime-types', version: '2.1.26', expected: ['MIT'] },
      { package_manager: :npm, name: 'ms', version: '2.0.0', expected: ['MIT'] },
      { package_manager: :npm, name: 'negotiator', version: '0.6.2', expected: ['MIT'] },
      { package_manager: :npm, name: 'on-finished', version: '2.3.0', expected: ['MIT'] },
      { package_manager: :npm, name: 'parseurl', version: '1.3.3', expected: ['MIT'] },
      { package_manager: :npm, name: 'path-to-regexp', version: '0.1.7', expected: ['MIT'] },
      { package_manager: :npm, name: 'proxy-addr', version: '2.0.6', expected: ['MIT'] },
      { package_manager: :npm, name: 'qs', version: '6.7.0', expected: ['BSD-3-Clause'] },
      { package_manager: :npm, name: 'range-parser', version: '1.2.1', expected: ['MIT'] },
      { package_manager: :npm, name: 'raw-body', version: '2.4.0', expected: ['MIT'] },
      { package_manager: :npm, name: 'safe-buffer', version: '5.1.2', expected: ['MIT'] },
      { package_manager: :npm, name: 'safer-buffer', version: '2.1.2', expected: ['MIT'] },
      { package_manager: :npm, name: 'send', version: '0.17.1', expected: ['MIT'] },
      { package_manager: :npm, name: 'serve-static', version: '1.14.1', expected: ['MIT'] },
      { package_manager: :npm, name: 'setprototypeof', version: '1.1.1', expected: ['ISC'] },
      { package_manager: :npm, name: 'statuses', version: '1.5.0', expected: ['MIT'] },
      { package_manager: :npm, name: 'toidentifier', version: '1.0.0', expected: ['MIT'] },
      { package_manager: :npm, name: 'type-is', version: '1.6.18', expected: ['MIT'] },
      { package_manager: :npm, name: 'unpipe', version: '1.0.0', expected: ['MIT'] },
      { package_manager: :npm, name: 'utils-merge', version: '1.0.1', expected: ['MIT'] },
      { package_manager: :npm, name: 'vary', version: '1.1.2', expected: ['MIT'] },
      { package_manager: :pypi, name: 'six', version: '1.14.0', expected: ['MIT'] },
      { package_manager: :rubygems, name: 'spandx', version: '0.1.0', expected: ['MIT'] },
      { package_manager: :yarn, name: 'accepts', version: '1.3.7', expected: ['MIT'] },
      { package_manager: :yarn, name: 'array-flatten', version: '1.1.1', expected: ['MIT'] },
      { package_manager: :yarn, name: 'body-parser', version: '1.19.0', expected: ['MIT'] },
      { package_manager: :yarn, name: 'bytes', version: '3.1.0', expected: ['MIT'] },
      { package_manager: :yarn, name: 'content-disposition', version: '0.5.3', expected: ['MIT'] },
      { package_manager: :yarn, name: 'content-type', version: '1.0.4', expected: ['MIT'] },
      { package_manager: :yarn, name: 'cookie', version: '0.4.0', expected: ['MIT'] },
      { package_manager: :yarn, name: 'cookie-signature', version: '1.0.6', expected: ['MIT'] },
      { package_manager: :yarn, name: 'debug', version: '2.6.9', expected: ['MIT'] },
      { package_manager: :yarn, name: 'depd', version: '1.1.2', expected: ['MIT'] },
      { package_manager: :yarn, name: 'destroy', version: '1.0.4', expected: ['MIT'] },
      { package_manager: :yarn, name: 'ee-first', version: '1.1.1', expected: ['MIT'] },
      { package_manager: :yarn, name: 'encodeurl', version: '1.0.2', expected: ['MIT'] },
      { package_manager: :yarn, name: 'escape-html', version: '1.0.3', expected: ['MIT'] },
      { package_manager: :yarn, name: 'etag', version: '1.8.1', expected: ['MIT'] },
      { package_manager: :yarn, name: 'express', version: '4.17.1', expected: ['MIT'] },
      { package_manager: :yarn, name: 'finalhandler', version: '1.1.2', expected: ['MIT'] },
      { package_manager: :yarn, name: 'forwarded', version: '0.1.2', expected: ['MIT'] },
      { package_manager: :yarn, name: 'fresh', version: '0.5.2', expected: ['MIT'] },
      { package_manager: :yarn, name: 'http-errors', version: '1.7.2', expected: ['MIT'] },
      { package_manager: :yarn, name: 'iconv-lite', version: '0.4.24', expected: ['MIT'] },
      { package_manager: :yarn, name: 'inherits', version: '2.0.3', expected: ['ISC'] },
      { package_manager: :yarn, name: 'ipaddr.js', version: '1.9.1', expected: ['MIT'] },
      { package_manager: :yarn, name: 'jquery', version: '3.4.0', expected: ['MIT'] },
      { package_manager: :yarn, name: 'media-typer', version: '0.3.0', expected: ['MIT'] },
      { package_manager: :yarn, name: 'merge-descriptors', version: '1.0.1', expected: ['MIT'] },
      { package_manager: :yarn, name: 'methods', version: '1.1.2', expected: ['MIT'] },
      { package_manager: :yarn, name: 'mime', version: '1.6.0', expected: ['MIT'] },
      { package_manager: :yarn, name: 'mime-db', version: '1.43.0', expected: ['MIT'] },
      { package_manager: :yarn, name: 'mime-types', version: '2.1.26', expected: ['MIT'] },
      { package_manager: :yarn, name: 'ms', version: '2.0.0', expected: ['MIT'] },
      { package_manager: :yarn, name: 'negotiator', version: '0.6.2', expected: ['MIT'] },
      { package_manager: :yarn, name: 'on-finished', version: '2.3.0', expected: ['MIT'] },
      { package_manager: :yarn, name: 'parseurl', version: '1.3.3', expected: ['MIT'] },
      { package_manager: :yarn, name: 'path-to-regexp', version: '0.1.7', expected: ['MIT'] },
      { package_manager: :yarn, name: 'proxy-addr', version: '2.0.6', expected: ['MIT'] },
      { package_manager: :yarn, name: 'qs', version: '6.7.0', expected: ['BSD-3-Clause'] },
      { package_manager: :yarn, name: 'range-parser', version: '1.2.1', expected: ['MIT'] },
      { package_manager: :yarn, name: 'raw-body', version: '2.4.0', expected: ['MIT'] },
      { package_manager: :yarn, name: 'safe-buffer', version: '5.1.2', expected: ['MIT'] },
      { package_manager: :yarn, name: 'safer-buffer', version: '2.1.2', expected: ['MIT'] },
      { package_manager: :yarn, name: 'send', version: '0.17.1', expected: ['MIT'] },
      { package_manager: :yarn, name: 'serve-static', version: '1.14.1', expected: ['MIT'] },
      { package_manager: :yarn, name: 'setprototypeof', version: '1.1.1', expected: ['ISC'] },
      { package_manager: :yarn, name: 'statuses', version: '1.5.0', expected: ['MIT'] },
      { package_manager: :yarn, name: 'toidentifier', version: '1.0.0', expected: ['MIT'] },
      { package_manager: :yarn, name: 'type-is', version: '1.6.18', expected: ['MIT'] },
      { package_manager: :yarn, name: 'unpipe', version: '1.0.0', expected: ['MIT'] },
      { package_manager: :yarn, name: 'utils-merge', version: '1.0.1', expected: ['MIT'] },
      { package_manager: :yarn, name: 'vary', version: '1.1.2', expected: ['MIT'] },
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

  describe "#managed_by?" do
    subject { described_class.new(package_manager: :nuget, name: 'jive', version: '0.1.0') }

    specify { expect(subject).to be_managed_by(:nuget) }
    specify { expect(subject).to be_managed_by('nuget') }
    specify { expect(subject).not_to be_managed_by('rubygems') }
    specify { expect(subject).not_to be_managed_by(nil) }
    specify { expect(subject).not_to be_managed_by(:rubygems) }
  end
end
