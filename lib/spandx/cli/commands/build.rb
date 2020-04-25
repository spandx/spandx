# frozen_string_literal: true

module Spandx
  module Cli
    module Commands
      class Build
        INDEXES = {
          maven: Spandx::Java::Index,
          nuget: Spandx::Dotnet::Index,
          dotnet: Spandx::Dotnet::Index,
          pypi: Spandx::Python::Index,
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
            sort_index!(index.name)
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

        def sort_index!(name)
          files("**/#{name}") do |path|
            IO.write(path, IO.readlines(path).sort.join)
          end
        end

        def files(pattern)
          Dir.glob(File.join(directory, pattern)).sort.each do |file|
            fullpath = File.join(directory, file)
            next if File.directory?(fullpath)
            next unless File.exist?(fullpath)

            yield fullpath
          end
        end
      end
    end
  end
end
