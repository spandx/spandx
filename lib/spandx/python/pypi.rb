# frozen_string_literal: true

module Spandx
  module Python
    class PyPI
      SUBSTITUTIONS = [
        '-py2.py3',
        '-py2',
        '-py3',
        '-none-any.whl',
        '.tar.gz',
        '.zip',
      ].freeze

      def initialize(sources: [Source.default])
        @sources = sources
      end

      def each
        each_package { |x| yield x }
      end

      def definition_for(name, version)
        @sources.each do |source|
          response = source.lookup(name, version)
          return response.fetch('info', {}) unless response.empty?
        end
        {}
      end

      def version_from(url)
        path = SUBSTITUTIONS.inject(URI.parse(url).path.split('/')[-1]) do |memo, item|
          memo.gsub(item, '')
        end

        return if path.rindex('-').nil?

        path.scan(/-\d+\..*/)[-1][1..-1]
      end

      private

      def each_package
        @sources.each do |source|
          html_from(source, '/simple/').css('a[href*="/simple"]').each do |node|
            each_version(source, node[:href]) do |dependency|
              definition = source.lookup(dependency[:name], dependency[:version])
              yield dependency.merge(license: definition['license'])
            end
          end
        end
      end

      def each_version(source, path)
        html = html_from(source, path)
        name = html.css('h1')[0].content.gsub('Links for ', '')
        html.css('a').each do |node|
          yield({ name: name, version: version_from(node[:href]) })
        end
      end

      def html_from(source, path)
        url = URI.join(source.uri.to_s, path).to_s
        Nokogiri::HTML(Spandx.http.get(url).body)
      end
    end
  end
end
