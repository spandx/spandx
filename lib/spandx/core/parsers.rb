# frozen_string_literal: true

module Spandx
  module Core
    module Parsers
      UNKNOWN = Class.new do
        def self.parse(*_args)
          []
        end
      end

      class << self
        def for(path, catalogue: Spandx::Spdx::Catalogue.from_git)
          result = ::Spandx::Core::Parser.find do |x|
            x.matches?(File.basename(path))
          end

          result&.new(catalogue: catalogue) || UNKNOWN
        end
      end
    end
  end
end
