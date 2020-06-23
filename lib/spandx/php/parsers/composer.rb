# frozen_string_literal: true

module Spandx
  module Php
    module Parsers
      class Composer < ::Spandx::Core::Parser
        def match?(path)
          path.basename.fnmatch? 'composer.lock'
        end

        def parse(path)
          items = Set.new
          composer_lock = Oj.load(path.read)
          composer_lock['packages'].concat(composer_lock['packages-dev']).each do |dependency|
            items.add(map_from(path, dependency))
          end
          items
        end

        private

        def map_from(path, dependency)
          Spandx::Core::Dependency.new(
            path: path,
            name: dependency['name'],
            version: dependency['version'],
            meta: dependency
          )
        end
      end
    end
  end
end
