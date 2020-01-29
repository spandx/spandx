# frozen_string_literal: true

module Spandx
  module Parsers
    class Maven < Base
      def self.matches?(filename)
      end

      def parse(filename)
        document = Nokogiri.XML(IO.read(filename))
        document.remove_namespaces!
        document.search('//project/dependencies/dependency').map do |node|
          Dependency.new(
            name: node.at_xpath('./artifactId').text,
            version: node.at_xpath('./version').text
          )
        end
      end
    end
  end
end
