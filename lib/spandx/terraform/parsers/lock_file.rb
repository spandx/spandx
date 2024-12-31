# frozen_string_literal: true

module Spandx
  module Terraform
    module Parsers
      class LockFile < ::Spandx::Core::Parser
        def initialize
          @parser = Hcl2::Parser.new
          super()
        end

        def match?(pathname)
          basename = pathname.basename
          basename.fnmatch?('.terraform.lock.hcl')
        end

        def parse(path)
          tree = @parser.parse(path.read)
          tree[:blocks].map do |block|
            version_arg = version_arg_from(block)
            ::Spandx::Core::Dependency.new(
              name: block[:name].to_s,
              version: version_arg[:value]&.to_s,
              path: path
            )
          end
        end

        private

        def version_arg_from(block)
          block[:arguments].find do |x|
            x[:name] == 'version'
          end
        end
      end
    end
  end
end
