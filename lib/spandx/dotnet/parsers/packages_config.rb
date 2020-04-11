# frozen_string_literal: true

module Spandx
  module Dotnet
    module Parsers
      class PackagesConfig < ::Spandx::Core::Parser
        def self.matches?(filename)
          filename.match?(/packages\.config/)
        end

        def parse(lockfile)
          Nokogiri::XML(IO.read(lockfile))
            .search('//package')
            .map { |node| map_from(node) }
        end

        private

        def map_from(node)
          name = attribute_for('id', node)
          version = attribute_for('version', node)
          ::Spandx::Core::Dependency.new(package_manager: :nuget, name: name, version: version)
        end

        def attribute_for(key, node)
          node.attribute(key)&.value&.strip || node.at_xpath("./#{key}")&.content&.strip
        end
      end
    end
  end
end
