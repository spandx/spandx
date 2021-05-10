# frozen_string_literal: true

module Spandx
  module Terraform
    module Parsers
      class LockFile
        def initialize; end

        def parse(path)
          parser = Spandx::Terraform::Parsers::Hcl.new
          tree = parser.parse(IO.read(path))
          puts tree.inspect
          []
        end
      end
    end
  end
end
