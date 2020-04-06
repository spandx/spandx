# frozen_string_literal: true

RSpec.describe '`spandx pull` command', type: :cli do
  it 'executes `spandx help pull` command successfully' do
    output = `spandx help pull`
    expected_output = <<~OUT
      Usage:
        spandx pull

      Options:
        -h, [--help], [--no-help]  # Display usage information

      Pull the latest offline cache
    OUT

    expect(output).to eq(expected_output)
  end
end
