# frozen_string_literal: true

require 'addressable/uri'
require 'bundler'
require 'csv'
require 'forwardable'
require 'json'
require 'logger'
require 'net/hippie'
require 'nokogiri'
require 'oj'
require 'parslet'
require 'pathname'
require 'sorted_set'
require 'yaml'
require 'zeitwerk'
require 'spandx/spandx'

loader = Zeitwerk::Loader.for_gem
loader.setup # ready!

module Spandx
  class Error < StandardError; end
  Rubygems = Ruby

  class << self
    attr_writer :airgap, :logger, :http, :git

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

    def git
      @git ||= {
        cache: ::Spandx::Core::Git.new(url: 'https://github.com/spandx/cache.git'),
        rubygems: ::Spandx::Core::Git.new(url: 'https://github.com/spandx/rubygems-cache.git'),
        spdx: ::Spandx::Core::Git.new(url: 'https://github.com/spdx/license-list-data.git', default_branch: 'master'),
      }
    end
  end
end

loader.eager_load
