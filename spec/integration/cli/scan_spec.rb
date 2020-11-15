# frozen_string_literal: true

RSpec.describe '`spandx scan` command', type: :cli do
  it 'executes `spandx help scan` command successfully' do
    output = `spandx help scan`
    expect(output).to eq(fixture_file_content('help-scan.expected'))
  end

  it 'executes `spandx scan Gemfile.lock`' do
    output = `spandx scan #{fixture_file('bundler/Gemfile.lock')} 2> /dev/null`
    expect(output).to eq(fixture_file_content('bundler/Gemfile.lock.expected'))
  end

  it 'executes `spandx scan gems.lock' do
    output = `spandx scan #{fixture_file('bundler/gems.lock')} 2> /dev/null`
    expect(output).to eq(fixture_file_content('bundler/gems.lock.expected'))
  end

  it 'executes `spandx scan Pipfile.lock`' do
    output = `spandx scan #{fixture_file('pip/Pipfile.lock')} 2> /dev/null`
    expect(output).to eq(fixture_file_content('pip/Pipfile.lock.expected'))
  end

  it 'executes `spandx scan yarnfile.lock`' do
    output = `spandx scan #{fixture_file('js/yarn.lock')} 2> /dev/null`
    expect(output).to eq(fixture_file_content('js/yarn.lock.expected'))
  end

  it 'executes `spandx scan composer.lock`' do
    output = `spandx scan #{fixture_file('composer/composer.lock')} 2> /dev/null`
    expect(output).to eq(fixture_file_content('composer/composer.lock.expected'))
  end

  it 'executes `spandx scan /lib/apk/db/installed' do
    output = `spandx scan #{fixture_file('os/lib/apk/db/installed')} 2> /dev/null`
    expect(output).to eq(fixture_file_content('os/lib/apk/db/installed.expected'))
  end

  it 'executes `spandx scan /var/lib/dpkg/status' do
    output = `spandx scan #{fixture_file('os/var/lib/dpkg/status')} 2> /dev/null`
    expect(output).to eq(fixture_file_content('os/var/lib/dpkg/status.expected'))
  end
end
