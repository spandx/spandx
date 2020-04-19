# frozen_string_literal: true

RSpec.describe '`spandx build` command', type: :cli do
  it 'executes `spandx help build` command successfully' do
    output = `spandx help build`
    expected_output = <<~OUT
      Usage:
        spandx build

      Options:
        -h, [--help], [--no-help]    # Display usage information
        -d, [--directory=DIRECTORY]  # Directory to build index in
                                     # Default: .index
        -l, [--logfile=LOGFILE]      # Path to a logfile
                                     # Default: /dev/null
        -i, [--index=INDEX]          # The specific index to build
                                     # Default: all

      Build a package index
    OUT
    expect(output).to eq(expected_output)
  end
end
