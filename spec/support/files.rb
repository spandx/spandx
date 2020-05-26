# frozen_string_literal: true

RSpec.configure do |config|
  config.include(Module.new do
    def fixture_file(path)
      Pathname.new(__FILE__).parent.join('../fixtures', path)
    end

    def fixture_file_content(path)
      fixture_file(path).read
    end

    def license_file(id)
      fixture_file_content("spdx/text/#{id}.txt")
    end

    def to_path(path)
      Pathname.new(path)
    end

    def within_tmp_dir
      Dir.mktmpdir do |directory|
        Dir.chdir(directory) do
          yield Pathname.new(directory)
        end
      end
    end
  end)
end
