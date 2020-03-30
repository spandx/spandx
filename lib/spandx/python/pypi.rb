# frozen_string_literal: true

module Spandx
  module Python
    class PyPI
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
        uri = URI.parse(url)
        path = uri.path.split('/')[-1]
          .gsub('-py2-none-any.whl', '')
          .gsub('-py2.py3-none-any.whl', '')
          .gsub('-py3-none-any.whl', '')
          .gsub('.tar.gz', '')
          .gsub('.zip', '')

        puts path
        index = path.rindex('-')
        return if index.nil?

        path[index+1..-1]
      end

      private

      def each_package
        @sources.each do |source|
          url = URI.join(source.uri.to_s, "/simple/").to_s
          html = Nokogiri::HTML(Spandx.http.get(url).body)
          html.css('a[href*="/simple"]').each do |node|
            url = URI.join(source.uri.to_s, node[:href]).to_s
            each_version(url) do |dependency|
              definition = source.lookup(dependency[:name], dependency[:version])
              yield dependency.merge(license: definition['license'])
            end
          end
        end
      end

      def each_version(url)
        html = Nokogiri::HTML(Spandx.http.get(url).body)
        name = html.css('h1')[0].content.gsub('Links for ', '')
        html.css('a').each do |node|
          yield({ name: name, version: version_from(node[:href]) })
        end
      end
    end
  end
end
