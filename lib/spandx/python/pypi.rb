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

      attr_reader :catalogue

      def initialize(http: Spandx.http, catalogue: ::Spandx::Spdx::Catalogue.empty)
        @definitions = {}
        @catalogue = catalogue
        super(http: http)
      end

      def with_http(http)
        self.class.new(http: http, catalogue: catalogue)
      end

      def matches?(dependency)
        dependency.package_manager == :pypi
      end

      def each_package(sources: default_sources)
        sources.each do |source|
          html_from(source, '/simple/').css('a[href*="/simple"]').each do |node|
            yield(source, node[:href])
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

      def licenses_for(dependency)
        licenses_from(
          definition_for(dependency.name, dependency.version, sources: sources_for(dependency))
        )
      end

      def licenses_from(info)
        license_map.for(info)
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

      # `each_version` yields one entry per distributable file -- wheel, sdist,
      # a wheel per python version -- so the same release recurs 3.24 times on
      # average. Deduplicating here rather than at rebuild time saves the
      # repeated lookups, not just the repeated rows.
      def resolve(worker, source, path)
        worker
          .enum_for(:each_version, source, path)
          .map { |dependency| [dependency[:name], dependency[:version]] }
          .uniq
          .map do |name, version|
            info = source.lookup(name, version, http: worker.http).fetch('info', {})
            [name, version, worker.licenses_from(info)]
          end
      end

      def version_from(url)
        path = cleanup(url)
        return if path.rindex('-').nil?

        section = path.scan(/-v?\d+\..*/)
        section = path.scan(/-v?\d+\.?.*/) if section.empty?
        return if section.empty?

        section[-1].sub(/\A-v?/, '')
      rescue StandardError => error
        warn([url, error].inspect)
      end

      private

      def license_map
        @license_map ||= ::Spandx::Python::Licenses.new(catalogue)
      end

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
