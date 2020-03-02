# frozen_string_literal: true

RSpec.describe '`spandx index update` command', type: :cli do
  it 'executes `spandx index help update` command successfully' do
    output = `spandx index help update`
    expected_output = <<~OUT
      Usage:
        spandx index update

      Options:
        -h, [--help], [--no-help]  # Display usage information

      Update the offline indexes
    OUT

    expect(output).to eq(expected_output)
  end
end
