# frozen_string_literal: true

RSpec.describe '`spandx scan` command', type: :cli do
  it 'executes `spandx help scan` command successfully' do
    output = `spandx help scan`
    expected_output = <<~OUT
      Usage:
        spandx scan LOCKFILE

      Options:
        -h, [--help], [--no-help]                     # Display usage information
        -R, [--recursive], [--no-recursive]           # Perform recursive scan
        -a, [--airgap], [--no-airgap]                 # Disable network connections
        -l, [--logfile=LOGFILE]                       # Path to a logfile
                                                      # Default: /dev/null
        -f, [--format=FORMAT]                         # Format of report. (table, csv, json, hash)
                                                      # Default: table
        -p, [--pull], [--no-pull]                     # Pull the latest cache before the scan
        -r, [--require=REQUIRE]                       # Causes spandx to load the library using require.
        -sp, [--show-progress], [--no-show-progress]  # Shows a progress bar
                                                      # Default: true

      Scan a lockfile and list dependencies/licenses
    OUT

    expect(output).to eq(expected_output)
  end

  it 'executes `spandx scan Gemfile.lock`' do
    gemfile_lock = fixture_file('bundler/Gemfile.lock')
    output = `spandx scan #{gemfile_lock} --format=json --no-show-progress`
    expected_output = <<~OUT
      {
        "version": "1.0",
        "dependencies": [
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
    output = `spandx scan #{gemfile_lock} --format=json --no-show-progress`
    expected_output = <<~OUT
      {
        "version": "1.0",
        "dependencies": [
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
    output = `spandx scan #{lockfile} --format=json --no-show-progress`
    expected_output = <<~OUT
      {
        "version": "1.0",
        "dependencies": [
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

  xit 'executes `spandx scan yarnfile.lock`' do
    lockfile = fixture_file('js/yarn.lock')
    output = `spandx scan #{lockfile} --no-show-progress`
    expect(output).to eq(fixture_file_content('js/yarn.lock.expected'))
  end

  it 'executes `spandx scan composer.lock`' do
    lockfile = fixture_file('composer/composer.lock')
    output = `spandx scan #{lockfile} --no-show-progress`

    expect(output).to eq(fixture_file_content('composer/composer.lock.expected'))
  end
end
