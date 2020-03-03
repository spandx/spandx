# frozen_string_literal: true

module Spandx
  module Dotnet
    class Index
      DEFAULT_DIR = File.expand_path(File.join(Dir.home, '.local', 'share', 'spandx'))
      attr_reader :directory

      def initialize(directory: DEFAULT_DIR)
        @directory = directory ? File.expand_path(directory) : DEFAULT_DIR
      end

      def licenses_for(name:, version:)
        search_key = [name, version].join
        open_data(name, mode: 'r') do |io|
          found = io.readlines.bsearch { |x| search_key <=> [x[0], x[1]].join }
          found ? found[2].split('-|-') : []
        end
      end

      def update!(catalogue:, output: self)
        Spandx::Dotnet::NugetGateway.new(catalogue: catalogue).each do |spec|
          next unless spec['licenseExpression']

          output.puts [spec['id'], spec['version']].inspect
          open_data(spec['id']) do |io|
            io << [spec['id'], spec['version'], spec['licenseExpression']]
          end
        end
      end

      private

      def digest_for(components)
        Digest::SHA1.hexdigest(Array(components).join('/'))
      end

      def open_data(key, mode: 'a')
        data_dir = data_dir_for(key)
        FileUtils.mkdir_p(data_dir)
        CSV.open(data_file_for(key), mode, force_quotes: true) do |csv|
          yield csv
        end
      end

      def data_dir_for(index_key)
        File.join(directory, index_key[0...2].downcase)
      end

      def data_file_for(key)
        File.join(data_dir_for(key), 'nuget')
      end
    end
  end
end
