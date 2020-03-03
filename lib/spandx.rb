# frozen_string_literal: true

require 'addressable/uri'
require 'bundler'
require 'csv'
require 'forwardable'
require 'json'
require 'net/hippie'
require 'nokogiri'
require 'pathname'

require 'spandx/core/content'
require 'spandx/core/database'
require 'spandx/core/dependency'
require 'spandx/core/guess'
require 'spandx/core/parser'
require 'spandx/core/parsers'
require 'spandx/core/report'
require 'spandx/core/score'
require 'spandx/dotnet/index'
require 'spandx/dotnet/nuget_gateway'
require 'spandx/dotnet/package_reference'
require 'spandx/dotnet/parsers/csproj'
require 'spandx/dotnet/parsers/packages_config'
require 'spandx/dotnet/parsers/sln'
require 'spandx/dotnet/project_file'
require 'spandx/gateways/http'
require 'spandx/gateways/pypi'
require 'spandx/java/metadata'
require 'spandx/java/parsers/maven'
require 'spandx/parsers/pipfile_lock'
require 'spandx/rubygems/gateway'
require 'spandx/rubygems/offline_index'
require 'spandx/rubygems/parsers/gemfile_lock'
require 'spandx/spdx/catalogue'
require 'spandx/spdx/gateway'
require 'spandx/spdx/license'
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
      @spdx_db ||= Spandx::Core::Database.new(url: 'https://github.com/spdx/license-list-data.git').tap(&:update!)
    end
  end
end
