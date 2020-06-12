# frozen_string_literal: true

module Spandx
  module Core
    class Plugin
      def enhance(_dependency)
        raise ::Spandx::Error, :enhance
      end

      class << self
        include Registerable

        def enhance(dependency)
          Plugin.all.inject(dependency) do |memo, plugin|
            plugin.enhance(memo)
          end
        end
      end
    end
  end
end
