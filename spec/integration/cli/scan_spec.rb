# frozen_string_literal: true

RSpec.describe '`spandx scan` command', type: :cli do
  it 'executes `spandx help scan` command successfully' do
    output = `spandx help scan`
    expect(output).to eq(fixture_file_content('help-scan.expected'))
  end

  it 'executes `spandx scan Gemfile.lock`' do
    output = `spandx scan #{fixture_file('bundler/Gemfile.lock')} --no-show-progress`
    expect(output).to eq(fixture_file_content('bundler/Gemfile.lock.expected'))
  end

  it 'executes `spandx scan gems.lock' do
    output = `spandx scan #{fixture_file('bundler/gems.lock')} --no-show-progress`
    expect(output).to eq(fixture_file_content('bundler/gems.lock.expected'))
  end

  it 'executes `spandx scan Pipfile.lock`' do
    output = `spandx scan #{fixture_file('pip/Pipfile.lock')} --no-show-progress`
    expect(output).to eq(fixture_file_content('pip/Pipfile.lock.expected'))
  end

  it 'executes `spandx scan yarnfile.lock`' do
    output = `spandx scan #{fixture_file('js/yarn.lock')} --no-show-progress`
    expect(output).to eq(fixture_file_content('js/yarn.lock.expected'))
  end

  it 'executes `spandx scan composer.lock`' do
    output = `spandx scan #{fixture_file('composer/composer.lock')} --no-show-progress`
    expect(output).to eq(fixture_file_content('composer/composer.lock.expected'))
  end
end
