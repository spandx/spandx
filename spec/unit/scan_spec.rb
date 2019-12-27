require 'spandx/commands/scan'

RSpec.describe Spandx::Commands::Scan do
  it "executes `scan` command successfully" do
    output = StringIO.new
    options = {}
    command = Spandx::Commands::Scan.new(options)

    command.execute(output: output)

    expect(output.string).to eq("OK\n")
  end
end
