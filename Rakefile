# frozen_string_literal: true

require 'bundler/audit/task'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'rake/extensiontask'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)
Bundler::Audit::Task.new

task build: :compile

Rake::ExtensionTask.new('spandx') do |ext|
  ext.lib_dir = 'lib/spandx'
end

task :licensed do
  sh 'bundle exec licensed cache'
  sh 'bundle exec licensed status'
end

task audit: ['bundle:audit', :licensed]
task default: %i[clobber compile spec]
