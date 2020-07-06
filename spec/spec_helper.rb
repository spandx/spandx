# frozen_string_literal: true

require 'bundler/setup'
require 'spandx'

require 'benchmark/ips'
require 'parslet/convenience'
require 'parslet/rig/rspec'
require 'rspec-benchmark'
require 'securerandom'
require 'tmpdir'
require 'webmock/rspec'

require './spec/support/profiler.rb'
require './spec/support/vcr.rb'
require './spec/support/files.rb'
require 'async/rspec'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.example_status_persistence_file_path = '.rspec_status'
  config.order = :random
  config.profile_examples = 10 unless config.files_to_run.one?
  config.warnings = false
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec do |c|
    c.verify_partial_doubles = true
  end
  Kernel.srand config.seed

  config.include RSpec::Benchmark::Matchers
end
