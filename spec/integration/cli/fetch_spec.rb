# frozen_string_literal: true

RSpec.describe '`spandx fetch` command', type: :cli do
  it 'executes `spandx help fetch` command successfully' do
    output = `spandx help fetch`
    expected_output = <<~OUT
      Usage:
        spandx fetch

      Options:
        -h, [--help], [--no-help]  # Display usage information

      Fetch the latest offline cache
    OUT

    expect(output).to eq(expected_output)
  end
end
