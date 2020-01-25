# frozen_string_literal: true

require 'bundler/setup'
require 'spandx'
require 'spandx/cli'
require 'webmock/rspec'
require 'securerandom'
Dir['./spec/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
  config.include(Module.new do
    def fixture_file(file)
      File.join(Dir.pwd, 'spec', 'fixtures', file)
    end

    def fixture_file_content(file)
      IO.read(fixture_file(file))
    end

    def license_file(id)
      json = JSON.parse(fixture_file_content("spdx/jsonld/#{id}.jsonld"))
      json['licenseText']
    end
  end)

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
