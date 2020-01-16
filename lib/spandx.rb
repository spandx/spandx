# frozen_string_literal: true

require 'forwardable'
require 'json'
require 'net/hippie'

require 'spandx/catalogue'
require 'spandx/gateways/http'
require 'spandx/gateways/spdx'
require 'spandx/gateways/pypi'
require 'spandx/license'
require 'spandx/parsers'
require 'spandx/version'

module Spandx
  class Error < StandardError; end
  def self.root
    Pathname.new(File.dirname(__FILE__)).join('../..')
  end

  def self.http
    @http ||= Net::Hippie::Client.new.tap do |client|
      client.logger = ::Logger.new('http.log')
      client.follow_redirects = 3
    end
  end
end
