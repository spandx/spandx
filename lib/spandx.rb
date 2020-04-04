# frozen_string_literal: true

require 'addressable/uri'
require 'bundler'
require 'csv'
require 'forwardable'
require 'json'
require 'logger'
require 'net/hippie'
require 'nokogiri'
require 'pathname'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.setup # ready!

module Spandx
  class Error < StandardError; end

  class << self
    attr_writer :airgap, :logger

    def root
      Pathname.new(File.dirname(__FILE__)).join('../..')
    end

    def airgap?
      @airgap
    end

    def http
      @http ||= Spandx::Core::Http.new
    end

    def logger
      @logger ||= Logger.new('/dev/null')
    end

    def spdx_db
      @spdx_db ||= Spandx::Core::Database
        .new(url: 'https://github.com/spdx/license-list-data.git')
        .tap(&:update!)
    end
  end
end

loader.eager_load
