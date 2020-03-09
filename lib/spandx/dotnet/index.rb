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

      def update!(catalogue:, output: StringIO.new)
        insert_latest(Spandx::Dotnet::NugetGateway.new(catalogue: catalogue)) do |page|
          output.puts "Checkpoint #{page}"
          checkpoint!(page)
        end
        # remove duplicates
        # sort records
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

      def checkpoints_filepath
        @checkpoints_filepath ||= File.join(directory, 'nuget.checkpoints')
      end

      def checkpoints
        @checkpoints ||= File.exist?(checkpoints_filepath) ? JSON.parse(IO.read(checkpoints_filepath)) : {}
      end

      def checkpoint!(page)
        checkpoints[page.to_s] = Time.now.utc
        IO.write(checkpoints_filepath, JSON.generate(checkpoints))
      end

      def insert(id, version, license)
        open_data(id) do |io|
          io << [id, version, license]
        end
      end

      def insert_latest(gateway)
        current_page = nil
        gateway.each do |spec, page|
          next unless spec['licenseExpression']
          break if checkpoints[page.to_s]

          yield current_page if current_page && page != current_page
          current_page = page
          insert(spec['id'], spec['version'], spec['licenseExpression'])
        end
      end
    end
  end
end
