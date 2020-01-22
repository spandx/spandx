# frozen_string_literal: true
require 'tmpdir'
require 'zip'

# https://docs.microsoft.com/en-us/nuget/api/package-base-address-resource
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

          dependencies[key] = Dependency.new(
            name: item[:id],
            version: item[:version],
            licenses: item.fetch(:licenses, []).map { |x| catalogue[x] }
          )

          each_dependency_of(item) do |id, version, licenses|
            next if id.start_with?('System.') || id.start_with?("Microsoft")

            stack.push(id: id, version: version, licenses: licenses)
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
        version = item[:version].strip
        #url = "https://api.nuget.org/v3-flatcontainer/#{id}/index.json"
        url = "https://api.nuget.org/v3-flatcontainer/#{id}/#{version}/#{id}.nuspec"
        puts url.inspect
        document = REXML::Document.new(Spandx.http.get(url).body)
        licenses = REXML::XPath.match(document, '//license').map { |x| x }
        puts document.to_s
        REXML::XPath.match(document, '//dependency').map do |package|
          attributes = package.attributes
          version = attributes['version'].split(',')[-1].gsub(')', '')
          puts [id, attributes['version']].inspect
          yield attributes['id'], version, licenses
        end
      end
    end
  end
end
