# frozen_string_literal: true
require 'tmpdir'
require 'zip'

module Spandx
  module Parsers
    class PackagesConfig < Base
      def self.matches?(filename)
        filename.match?(/packages\.config/)
      end

      def parse(lockfile)
        document = REXML::Document.new(IO.read(lockfile))
        dependencies = {}
        stack = []

        REXML::XPath.match(document, '//package').map do |package|
          attributes = package.attributes
          stack.push(id: attributes['id'], version: attributes['version'])
        end

        until stack.empty?
          item = stack.pop
          key = key_for(item)

          next if dependencies.key?(key)

          dependencies[key] = Dependency.new(name: item[:id], version: item[:version])

          each_dependency_of(item) do |id, version|
            next if id.start_with?('System.') || id.start_with?("Microsoft")

            stack.push(id: id, version: version)
          end
        end

        dependencies.values
      end

      private

      def key_for(item = {})
        [item[:id], item[:version]].join('-')
      end

      def each_dependency_of(item = {})
        id = item[:id]
        version = item[:version]
        url = "https://api.nuget.org/v3-flatcontainer/#{id}/#{version}/#{id}.nuspec"
        download(url) do |file|
          ::Zip::File.open file do |zipfile|
            document = REXML::Document.new(zipfile.read("#{id}.nuspec"))
            REXML::XPath.match(document, '//dependency').map do |package|
              attributes = package.attributes
              version = attributes['version'].split(',')[-1].gsub(')', '')
              yield attributes['id'], version
            end
          end
        end
      end

      def download(url)
        Dir.mktmpdir do |dir|
          if system("curl -s --output item.nupkg #{url}")
            yield File.expand_path('item.nupkg')
          end
        end
      end
    end
  end
end
