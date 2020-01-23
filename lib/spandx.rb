# frozen_string_literal: true

require 'bundler'
require 'forwardable'
require 'json'
require 'licensee'
require 'net/hippie'
require 'nokogiri'
require 'pathname'

require 'spandx/catalogue'
require 'spandx/dependency'
require 'spandx/gateways/http'
require 'spandx/gateways/nuget'
require 'spandx/gateways/pypi'
require 'spandx/gateways/spdx'
require 'spandx/license'
require 'spandx/parsers'
require 'spandx/report'
require 'spandx/version'

module Spandx
  class Error < StandardError; end

  class << self
    def root
      Pathname.new(File.dirname(__FILE__)).join('../..')
    end

    def http
      @http ||= Spandx::Gateways::Http.new
    end
  end
end
