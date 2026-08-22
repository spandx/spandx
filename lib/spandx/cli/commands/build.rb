# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      class Build
        INDEXES = {
          composer: Spandx::Php::Index,
          dotnet: Spandx::Dotnet::Index,
          maven: Spandx::Java::Index,
          npm: Spandx::Js::Index,
          nuget: Spandx::Dotnet::Index,
          pypi: Spandx::Python::Index,
          rubygems: Spandx::Ruby::Index,
          yarn: Spandx::Js::Index,
        }.freeze

        def initialize(options)
          @options = options
        end

        def execute(output: $stdout)
          # A build makes millions of requests over hours. The C resolver has no
          # timeout, so a lookup that wedges -- as one did when this machine's
          # resolver state changed mid-run -- costs a worker permanently.
          # Ruby's resolver honours timeouts, and only the build pays for it.
          require 'resolv-replace'

          catalogue = Spandx::Spdx::Catalogue.from_git
          build_buckets
          indexes.each do |index|
            output.puts index.name
            index.update!(catalogue: catalogue, output: output)
          end
          output.puts 'OK'
        end

        private

        def indexes
          index = INDEXES[@options[:index]&.to_sym]

          if index.nil?
            INDEXES.values.uniq.map { |x| build_index(x) }
          else
            [build_index(index)]
          end
        end

        def build_index(klass)
          kwargs = { directory: directory }
          kwargs[:concurrency] = concurrency if concurrency
          klass.new(**kwargs)
        end

        def concurrency
          @options[:concurrency] && Integer(@options[:concurrency])
        end

        def directory
          @options.fetch(:directory, File.join(Dir.pwd, '.index'))
        end

        def build_buckets
          (0x00..0xFF).map { |x| x.to_s(16).rjust(2, '0').downcase }.each do |hex|
            FileUtils.mkdir_p(File.join(directory, hex))
          end
        end
      end
    end
  end
end
