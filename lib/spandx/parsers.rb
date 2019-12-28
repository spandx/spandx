# frozen_string_literal: true

require 'spandx/parsers/base'
require 'spandx/parsers/gemfile_lock'
require 'spandx/parsers/pipfile_lock'

module Spandx
  module Parsers
    class << self
      def for(path)
        result = ::Spandx::Parsers::Base.find do |x|
          x.matches?(File.basename(path))
        end

        result&.new
      end
    end
  end
end
