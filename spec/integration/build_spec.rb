# frozen_string_literal: true

RSpec.describe '`spandx build` command', type: :cli do
  it 'executes `spandx help build` command successfully' do
    output = `spandx help build`
    expected_output = <<~OUT
      Usage:
        spandx build

      Options:
        -h, [--help], [--no-help]  # Display usage information

      Command description...
    OUT

    expect(output).to eq(expected_output)
  end
end
