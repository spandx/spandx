# frozen_string_literal: true

RSpec.describe '`spandx pull` command', type: :cli do
  it 'executes `spandx help pull` command successfully' do
    output = `spandx help pull`
    expect(output).to eq(fixture_file_content('help-pull.expected'))
  end
end
