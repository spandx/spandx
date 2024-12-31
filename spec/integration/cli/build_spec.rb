# frozen_string_literal: true

RSpec.describe '`spandx build` command', type: :cli do
  it 'executes `spandx help build` command successfully' do
    output = `spandx help build`
    expect(output).to eq(fixture_file_content('help-build.expected'))
  end
end
