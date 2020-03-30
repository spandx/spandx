RSpec.describe Spandx::Python::Index do
  subject { described_class.new(directory: directory) }
  let(:directory) { Dir.tmpdir }

end
