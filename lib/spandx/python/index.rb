# frozen_string_literal: true

module Spandx
  module Python
    class Index
      attr_reader :directory, :source

      def initialize(directory:)
        @directory = directory
        @source = 'https://pypi.org'
      end

      def update!(catalogue:, output:)
        output.puts catalogue.inspect
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
          url = "#{source}/#{node.attribute('href').value}"
          each_version(url) do |version|
            yield version
          end
        end
      end

      def each_version(url)
        Nokogiri::HTML(http.get(url).body).css('a').each do |node|
          url = node.attribute('href').value
          yield url
        end
      end

      def http
        Spandx.http
      end
    end
  end
end
