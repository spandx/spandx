# frozen_string_literal: true

module Spandx
  module Spdx
    class CompositeLicense < License
      def self.from_expression(expression, catalogue)
        tree = Spdx::Expression.new.parse(expression)
        new(tree[0], catalogue)
      rescue Parslet::ParseFailed
        nil
      end

      def initialize(tree, catalogue)
        @catalogue = catalogue
        @tree = tree
        super({})
      end

      def id
        if right
          [left.id, operator, right.id].compact.join(' ').squeeze(' ').strip
        else
          left.id.to_s
        end
      end

      def name
        if right
          [left.name, operator, right.name].compact.join(' ').squeeze(' ').strip
        else
          left.name
        end
      end

      private

      def left
        node_for(@tree[:left])
      end

      def operator
        @tree[:op].to_s.upcase
      end

      def right
        node_for(@tree[:right])
      end

      def node_for(item)
        return if item.nil?

        if item.is_a?(Hash)
          self.class.new(item, @catalogue)
        else
          @catalogue[item.to_s] || License.unknown(item.to_s)
        end
      end
    end
  end
end
