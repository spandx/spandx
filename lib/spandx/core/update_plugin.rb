# frozen_string_literal: true

module Spandx
  module Core
    class UpdatePlugin < Spandx::Core::Plugin
      def enhance(dependency)
        if dependency.package_manager == :rubygems
          Dir.chdir(dependency.path.parent) do
            Bundler.with_unbundled_env do
              puts "Updating... #{dependency.name}"
              system "bundle update #{dependency.name} --conservative"
              system "git diff"
              system "git checkout ."
            end
          end
        end
      end
    end
  end
end
