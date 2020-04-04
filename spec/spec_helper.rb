# frozen_string_literal: true

require 'bundler/setup'
require 'spandx'

require 'rspec-benchmark'
require 'securerandom'
require 'tmpdir'
require 'webmock/rspec'

Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
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

  config.before :all do
    Spandx::Core::Database
      .new(url: 'https://github.com/mokhan/spandx-rubygems.git')
      .update!
    Spandx::Core::Database
      .new(url: 'https://github.com/mokhan/spandx-index.git')
      .update!
  end

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
