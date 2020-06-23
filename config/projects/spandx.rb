#
# Copyright 2020 YOUR NAME
#
# All Rights Reserved.
#

name "spandx"
maintainer "mo.khan@gmail.com"
homepage "https://github.com/spandx/spandx"

# Defaults to C:/spandx on Windows
# and /opt/spandx on all other platforms
install_dir "#{default_root}/#{name}"

build_version Omnibus::BuildVersion.semver
build_iteration 1

# Creates required build directories
dependency "preparation"
dependency "spandx"

# spandx dependencies/components
# dependency "somedep"

exclude "**/.git"
exclude "**/bundler/git"
