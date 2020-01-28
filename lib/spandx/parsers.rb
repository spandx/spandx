# frozen_string_literal: true

require 'spandx/parsers/base'
require 'spandx/parsers/csproj'
require 'spandx/parsers/gemfile_lock'
require 'spandx/parsers/packages_config'
require 'spandx/parsers/pipfile_lock'
require 'spandx/parsers/sln'

module Spandx
  module Parsers
    UNKNOWN = Class.new do
      def self.parse(*_args)
        []
      end
    end

    class << self
      def for(path, catalogue: Spandx::Catalogue.from_git)
        result = ::Spandx::Parsers::Base.find do |x|
          x.matches?(File.basename(path))
        end

        result&.new(catalogue: catalogue) || UNKNOWN
      end
    end
  end
end
