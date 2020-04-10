# frozen_string_literal: true

module Spandx
  module Dotnet
    class Index
      DEFAULT_DIR = File.expand_path(File.join(Dir.home, '.local', 'share', 'spandx'))
      attr_reader :directory, :name

      def initialize(directory: DEFAULT_DIR)
        @directory = directory ? File.expand_path(directory) : DEFAULT_DIR
        @name = 'nuget'
      end

      def licenses_for(name:, version:)
        search_key = [name, version].join
        CSV.open(data_file_for(name), 'r') do |io|
          found = io.readlines.bsearch { |x| search_key <=> [x[0], x[1]].join }
          found ? found[2].split('-|-') : []
        end
      end

      def update!(catalogue:, output: StringIO.new)
        catalogue.version
        insert_latest(Spandx::Dotnet::NugetGateway.new) do |page|
          output.puts "Checkpoint #{page}"
          checkpoint!(page)
        end
        sort_index!
      end

      private

      def files(pattern)
        Dir.glob(pattern, base: directory).sort.each do |file|
          fullpath = File.join(directory, file)
          yield fullpath unless File.directory?(fullpath)
        end
      end

      def sort_index!
        files('**/nuget') do |path|
          next if File.extname(path) == '.checkpoints'

          IO.write(path, IO.readlines(path).sort.join)
        end
      end

      def digest_for(components)
        Digest::SHA1.hexdigest(Array(components).join('/'))
      end

      def data_dir_for(name)
        digest = digest_for(name)
        File.join(directory, digest[0...2].downcase)
      end

      def data_file_for(name)
        File.join(data_dir_for(name), 'nuget')
      end

      def checkpoints_filepath
        @checkpoints_filepath ||= File.join(directory, 'nuget.checkpoints')
      end

      def checkpoints
        @checkpoints ||= File.exist?(checkpoints_filepath) ? JSON.parse(IO.read(checkpoints_filepath)) : {}
      end

      def checkpoint!(page)
        checkpoints[page.to_s] = Time.now.utc
        IO.write(checkpoints_filepath, JSON.pretty_generate(checkpoints))
      end

      def insert(name, version, license)
        path = license ? data_file_for(name) : dead_letter_path
        FileUtils.mkdir_p(File.dirname(path))
        IO.write(
          path,
          CSV.generate_line([name, version, license], force_quotes: true),
          mode: 'a'
        )
      end

      def completed_pages
        checkpoints.keys.map(&:to_i)
      end

      def dead_letter_path
        @dead_letter_path ||= File.join(directory, 'nuget.unknown')
      end

      def insert_latest(gateway)
        current_page = completed_pages.max || 0
        gateway.each(start_page: current_page) do |spec, page|
          break if checkpoints[page.to_s]

          yield current_page if current_page && page != current_page
          current_page = page
          insert(spec['id'], spec['version'], spec['licenseExpression'])
        end
      end
    end
  end
end
