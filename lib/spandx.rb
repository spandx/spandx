# frozen_string_literal: true

require 'addressable/uri'
require 'bundler'
require 'forwardable'
require 'json'
require 'net/hippie'
require 'nokogiri'
require 'pathname'

require 'spandx/catalogue'
require 'spandx/content'
require 'spandx/database'
require 'spandx/dependency'
require 'spandx/gateways/http'
require 'spandx/gateways/nuget'
require 'spandx/gateways/pypi'
require 'spandx/gateways/rubygems'
require 'spandx/gateways/spdx'
require 'spandx/guess'
require 'spandx/index'
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

    def spdx_db
      @spdx_db ||= Spandx::Database.new(url: 'https://github.com/spdx/license-list-data.git').tap(&:update!)
    end
  end
end
