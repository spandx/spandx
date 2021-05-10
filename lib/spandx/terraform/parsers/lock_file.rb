# frozen_string_literal: true

module Spandx
  module Terraform
    module Parsers
      class LockFile < ::Spandx::Core::Parser
        def initialize
          @parser = Spandx::Terraform::Parsers::Hcl.new
        end

        def match?(pathname)
          basename = pathname.basename
          basename.fnmatch?('.terraform.lock.hcl')
        end

        def parse(path)
          tree = @parser.parse(path.read)
          tree[:blocks].map do |block|
            ::Spandx::Core::Dependency.new(
              name: block[:name],
              version: block[:arguments].find { |x| x[:name] == 'version' }[:value],
              path: path
            )
          end
        end
      end
    end
  end
end
