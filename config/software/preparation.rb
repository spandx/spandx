name "preparation"
description "the steps required to prepare the build"
default_version "1.0.0"

license :project_license
skip_transitive_dependency_licensing true

build do
  block do
    touch "#{install_dir}/embedded/lib/.gitkeep"
    touch "#{install_dir}/embedded/bin/.gitkeep"
    touch "#{install_dir}/bin/.gitkeep"
  end
end
