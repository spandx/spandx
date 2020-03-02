# frozen_string_literal: true

require 'spandx/commands/index/update'

RSpec.describe Spandx::Commands::Index::Update do
  it 'executes `index update` command successfully' do
    output = StringIO.new
    options = {}
    command = described_class.new(options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
