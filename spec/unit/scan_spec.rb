# frozen_string_literal: true

require 'spandx/commands/scan'

RSpec.describe Spandx::Commands::Scan do
  it 'executes `scan` command successfully' do
    output = StringIO.new
    options = {}
    command = described_class.new(nil, options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
