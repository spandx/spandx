# frozen_string_literal: true

module Spandx
  module Php
    module Parsers
      class Composer < ::Spandx::Core::Parser
        def matches?(filename)
          File.basename(filename) == 'composer.lock'
        end

        def parse(file_path)
          items = Set.new
          composer_lock = JSON.parse(IO.read(file_path))
          composer_lock['packages'].concat(composer_lock['packages-dev']).each do |dependency|
            items.add(map_from(dependency))
          end
          items
        end

        private

        def map_from(dependency)
          Spandx::Core::Dependency.new(
            package_manager: :composer,
            name: dependency['name'],
            version: dependency['version'],
            meta: dependency
          )
        end
      end
    end
  end
end
