# frozen_string_literal: true

RSpec.describe '`spandx index build` command', type: :cli do
  it 'executes `spandx index help build` command successfully' do
    output = `spandx index help build`
    expected_output = <<~OUT
      Usage:
        spandx index build

      Options:
        -h, [--help], [--no-help]    # Display usage information
        -d, [--directory=DIRECTORY]  # Directory to build index in
                                     # Default: .index/nuget

      Build a package index
    OUT
    expect(output).to eq(expected_output)
  end
end
