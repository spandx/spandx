# frozen_string_literal: true

module Spandx
  module Dotnet
    module Parsers
      class PackagesConfig < ::Spandx::Core::Parser
        def match?(path)
          path.basename.fnmatch?('packages.config')
        end

        def parse(path)
          Nokogiri::XML(path.read)
            .search('//package')
            .map { |node| map_from(path, node) }
        end

        private

        def map_from(path, node)
          name = attribute_for('id', node)
          version = attribute_for('version', node)
          ::Spandx::Core::Dependency.new(name: name, version: version, path: path)
        end

        def attribute_for(key, node)
          node.attribute(key)&.value&.strip || node.at_xpath("./#{key}")&.content&.strip
        end
      end
    end
  end
end
