# frozen_string_literal: true

module Spandx
  module Python
    class Index
      include Enumerable

      attr_reader :directory, :source

      def initialize(directory:)
        @directory = directory
        @source = 'https://pypi.org'
      end

      def update!(catalogue:, output:)
        output.puts catalogue
        each do |dependency|
          output.puts dependency.inspect
        end
      end

      def each
        each_package do |x|
          puts x.inspect
        end
      end

      private

      def each_package(url = "#{source}/simple/")
        Nokogiri::HTML(http.get(url).body).css('a[href*="/simple"]').each do |node|
          each_version("#{source}/#{node.attribute('href').value}") do |version|
            yield version
          end
        end
      end

      def each_version(url)
        html = Nokogiri::HTML(http.get(url).body)
        name = html.css('h1')[0].content.gsub('Links for ', '')
        html.css('a').each do |node|
          url = node.attribute('href').value
          yield({ name: name, version: version_from(url), url: url })
        end
      end

      def version_from(url)
        _name, version, _rest = url.split('/')[-1].split('#')[0].split('-')
        version
      end

      def http
        Spandx.http
      end
    end
  end
end
