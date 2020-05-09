# frozen_string_literal: true

require 'bundler/setup'
require 'spandx'

require 'parslet/convenience'
require 'parslet/rig/rspec'
require 'rspec-benchmark'
require 'ruby-prof'
require 'securerandom'
require 'tmpdir'
require 'webmock/rspec'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

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
  config.include(Module.new do
    def fixture_file(file)
      File.join(File.dirname(__FILE__), 'fixtures', file)
    end

    def fixture_file_content(file)
      IO.read(fixture_file(file))
    end

    def license_file(id)
      fixture_file_content("spdx/text/#{id}.txt")
    end
  end)
end
