# frozen_string_literal: true

module Spandx
  module Python
    class Pypi < ::Spandx::Core::Gateway
      SUBSTITUTIONS = [
        '-py2.py3',
        '-py2',
        '-py3',
        '-none-any.whl',
        '.tar.gz',
        '.zip',
      ].freeze

      def initialize(http: Spandx.http)
        @http = http
        @definitions = {}
      end

      def matches?(dependency)
        dependency.package_manager == :pypi
      end

      def each(sources: default_sources)
        each_package(sources) { |x| yield x }
      end

      def licenses_for(dependency)
        definition = definition_for(
          dependency.name,
          dependency.version,
          sources: sources_for(dependency)
        )
        [definition['license']]
      end

      def definition_for(name, version, sources: default_sources)
        @definitions.fetch([name, version]) do |key|
          sources.each do |source|
            response = source.lookup(name, version)
            next if response.empty?

            match = response.fetch('info', {})
            @definitions[key] = match
            return match
          end
          {}
        end
      end

      def version_from(url)
        path = cleanup(url)
        return if path.rindex('-').nil?

        section = path.scan(/-\d+\..*/)
        section = path.scan(/-\d+\.?.*/) if section.empty?
        section[-1][1..-1]
      rescue StandardError => error
        warn([url, error].inspect)
      end

      private

      attr_reader :http

      def cleanup(url)
        SUBSTITUTIONS.inject(URI.parse(url).path.split('/')[-1]) do |memo, item|
          memo.gsub(item, '')
        end
      end

      def sources_for(dependency)
        return default_sources if dependency.meta.empty?

        ::Spandx::Python::Source.sources_from(dependency.meta)
      end

      def default_sources
        [Source.default]
      end

      def each_package(sources)
        sources.each do |source|
          html_from(source, '/simple/').css('a[href*="/simple"]').each do |node|
            each_version(source, node[:href]) do |dependency|
              definition = source.lookup(dependency[:name], dependency[:version], http: http)
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
        response = http.get(url)
        if http.ok?(response)
          Nokogiri::HTML(response.body)
        else
          Nokogiri::HTML('<html><head></head><body></body></html>')
        end
      end
    end
  end
end
