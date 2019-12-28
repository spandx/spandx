# frozen_string_literal: true

module Spandx
  module Parsers
    def self.for(_path)
      Parsers::GemfileLock.new
    end
  end
end

require 'spandx/parsers/gemfile_lock'
