# frozen_string_literal: true

module Spandx
  module Php
    module Parsers
      class Composer < ::Spandx::Core::Parser
        def self.matches?(filename)
          File.basename(filename) == 'composer.lock'
        end

        def parse(file_path)
          items = Set.new
          composer_lock = JSON.parse(IO.read(file_path))
          composer_lock['packages'].concat(composer_lock['packages-dev']).each do |dependency|
            items.add(Spandx::Core::Dependency.new(
                        name: dependency['name'],
                        version: dependency['version'],
                        licenses: catelogue_licenses(dependency['license']),
                        meta: dependency
                      ))
          end
          items
        end

        private

        def catelogue_licenses(licenses)
          licenses.map do |license_name|
            found_license = catalogue[license_name]
            Spandx.logger.info("Could not find SPDX license id for #{license_name}") if found_license.nil?

            found_license
          end
        end
      end
    end
  end
end
