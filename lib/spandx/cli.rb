# frozen_string_literal: true

require 'nanospinner'
require 'thor'
require 'tty-screen'
require 'terminal-table'

module Spandx
  module Cli
    Error = Class.new(StandardError)
  end
end
