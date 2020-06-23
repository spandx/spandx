# frozen_string_literal: true

require 'thor'
require 'tty-spinner'
require 'terminal-table'

module Spandx
  module Cli
    Error = Class.new(StandardError)
  end
end
