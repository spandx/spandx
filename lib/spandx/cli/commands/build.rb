# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      class Build
        INDEXES = {
          dotnet: Spandx::Dotnet::Index,
          maven: Spandx::Java::Index,
          nuget: Spandx::Dotnet::Index,
          pypi: Spandx::Python::Index,
          rubygems: Spandx::Ruby::Index,
        }.freeze

        def initialize(options)
          @options = options
        end

        def execute(output: $stdout)
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
            INDEXES.values.uniq.map { |x| x.new(directory: directory) }
          else
            [index.new(directory: directory)]
          end
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
