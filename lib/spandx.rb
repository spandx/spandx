# frozen_string_literal: true

require 'forwardable'
require 'json'
require 'net/hippie'

require 'spandx/catalogue'
require 'spandx/catalogue_gateway'
require 'spandx/license'
require 'spandx/parsers'
require 'spandx/version'

module Spandx
  class Error < StandardError; end
end
