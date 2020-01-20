# frozen_string_literal: true

require 'vcr'

VCR.configure do |x|
  x.cassette_library_dir = 'spec/fixtures/recordings'
  x.hook_into :webmock
end
