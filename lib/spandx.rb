# frozen_string_literal: true

require 'addressable/uri'
require 'bundler'
require 'csv'
require 'etc'
require 'forwardable'
require 'json'
require 'logger'
require 'net/hippie'
require 'nokogiri'
require 'pathname'
require 'yaml'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.setup # ready!

module Spandx
  class Error < StandardError; end
  Rubygems = Ruby

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

    def git
      @git ||= {
        cache: ::Spandx::Core::Git.new(url: 'https://github.com/mokhan/spandx-index.git'),
        rubygems: ::Spandx::Core::Git.new(url: 'https://github.com/mokhan/spandx-rubygems.git'),
        spdx: ::Spandx::Core::Git.new(url: 'https://github.com/spdx/license-list-data.git'),
      }
    end
  end
end

loader.eager_load
