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

require 'spandx/core/cache'
require 'spandx/core/content'
require 'spandx/core/database'
require 'spandx/core/dependency'
require 'spandx/core/guess'
require 'spandx/core/http'
require 'spandx/core/parser'
require 'spandx/core/report'
require 'spandx/core/score'
require 'spandx/dotnet/index'
require 'spandx/dotnet/nuget_gateway'
require 'spandx/dotnet/package_reference'
require 'spandx/dotnet/parsers/csproj'
require 'spandx/dotnet/parsers/packages_config'
require 'spandx/dotnet/parsers/sln'
require 'spandx/dotnet/project_file'
require 'spandx/java/index'
require 'spandx/java/metadata'
require 'spandx/java/parsers/maven'
require 'spandx/js/parsers/yarn'
require 'spandx/python/parsers/pipfile_lock'
require 'spandx/python/index'
require 'spandx/python/pypi'
require 'spandx/python/source'
require 'spandx/rubygems/gateway'
require 'spandx/rubygems/parsers/gemfile_lock'
require 'spandx/spdx/catalogue'
require 'spandx/spdx/gateway'
require 'spandx/spdx/license'
require 'spandx/version'

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
