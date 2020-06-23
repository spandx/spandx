require_relative '../../lib/spandx/version'

name "spandx"
default_version Spandx::VERSION

license :MIT
skip_transitive_dependency_licensing true

dependency "ruby"
dependency "rubygems"

build do
  block do
    gem "install spandx --bindir #{install_dir}/bin --no-document -v #{version}"
  end
end
