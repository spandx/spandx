# frozen_string_literal: true

RSpec.describe '`spandx index` command', type: :cli do
  it 'executes `spandx help index` command successfully' do
    output = `spandx help index`
    expected_output = <<~OUT
      Commands:
        spandx index help [COMMAND]  # Describe subcommands or one specific subcommand
        spandx index update          # Update the offline indexes

    OUT

    expect(output).to eq(expected_output)
  end
end
