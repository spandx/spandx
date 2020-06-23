#require_relative '../../lib/spandx/version'

name "spandx"
#version Spandx::VERSION
version "0.13.5"

license :MIT
skip_transitive_dependency_licensing true

dependency "ruby"
dependency "rubygems"

build do
  block do
    gem "install spandx -n #{install_dir}/bin --no-document -v #{version}"
  end
end
