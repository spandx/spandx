RSpec.describe "`spandx scan` command", type: :cli do
  it "executes `spandx help scan` command successfully" do
    output = `spandx help scan`
    expected_output = <<-OUT
Usage:
  spandx scan

Options:
  -h, [--help], [--no-help]  # Display usage information

Command description...
    OUT

    expect(output).to eq(expected_output)
  end
end
