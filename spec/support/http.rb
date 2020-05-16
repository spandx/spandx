# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    Spandx.http = Spandx::Core::Http.new
  end
end
