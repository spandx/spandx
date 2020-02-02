# frozen_string_literal: true

RSpec.describe '`spandx scan` command', type: :cli do
  it 'executes `spandx help scan` command successfully' do
    output = `spandx help scan`
    expected_output = <<~OUT
Usage:
  spandx scan LOCKFILE

Options:
  -h, [--help], [--no-help]  # Display usage information

Scan a lockfile and list dependencies/licenses
    OUT

    expect(output).to eq(expected_output)
  end

  it 'executes `spandx scan Gemfile.lock`' do
    gemfile_lock = fixture_file('bundler/Gemfile.lock')
    output = `spandx scan #{gemfile_lock}`
    expected_output = <<~OUT
      {
        "version": "1.0",
        "packages": [
          {
            "name": "net-hippie",
            "version": "0.2.7",
            "licenses": [
              "MIT"
            ]
          }
        ]
      }
    OUT
    expect(output).to eq(expected_output)
  end

  it 'executes `spandx scan gems.lock' do
    gemfile_lock = fixture_file('bundler/gems.lock')
    output = `spandx scan #{gemfile_lock}`
    expected_output = <<~OUT
      {
        "version": "1.0",
        "packages": [
          {
            "name": "net-hippie",
            "version": "0.2.7",
            "licenses": [
              "MIT"
            ]
          }
        ]
      }
    OUT
    expect(output).to eq(expected_output)
  end

  it 'executes `spandx scan Pipfile.lock`' do
    lockfile = fixture_file('pip/Pipfile.lock')
    output = `spandx scan #{lockfile}`
    expected_output = <<~OUT
      {
        "version": "1.0",
        "packages": [
          {
            "name": "six",
            "version": "1.13.0",
            "licenses": [
              "MIT"
            ]
          }
        ]
      }
    OUT
    expect(output).to eq(expected_output)
  end
end
