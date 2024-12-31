# frozen_string_literal: true

require 'ruby-prof'

RSpec.configure do |config|
  config.include(Module.new do
    def with_profiler(*_args)
      RubyProf::GraphPrinter
        .new(RubyProf.profile { yield })
        .print($stdout, {})
    end
  end)
end
