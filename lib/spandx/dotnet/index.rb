# frozen_string_literal: true

module Spandx
  module Dotnet
    class Index
      DEFAULT_DIR = File.expand_path(File.join(Dir.home, '.local', 'share', 'spandx'))
      attr_reader :directory, :name, :gateway

      def initialize(directory: DEFAULT_DIR)
        @directory = directory ? File.expand_path(directory) : DEFAULT_DIR
        @name = 'nuget'
        @gateway = Spandx::Dotnet::NugetGateway.new
      end

      def licenses_for(name:, version:)
        search_key = [name, version].join
        CSV.open(data_file_for(name), 'r') do |io|
          found = io.readlines.bsearch { |x| search_key <=> [x[0], x[1]].join }
          found ? found[2].split('-|-') : []
        end
      end

      def update!(*)
        queue = Queue.new
        [fetch(queue), save(queue)].each(&:join)
      end

      private

      def fetch(queue)
        Thread.new do
          gateway.each do |spec|
            queue.enq(spec)
          end
          queue.enq(:stop)
        end
      end

      def save(queue)
        Thread.new do
          loop do
            item = queue.deq
            break if item == :stop

            insert!(item['id'], item['version'], item['licenseExpression'])
          end
        end
      end

      def digest_for(components)
        Digest::SHA1.hexdigest(Array(components).join('/'))
      end

      def data_dir_for(name)
        File.join(directory, digest_for(name)[0...2].downcase)
      end

      def data_file_for(name)
        File.join(data_dir_for(name), 'nuget')
      end

      def insert!(name, version, license)
        return if name.nil? || name.empty?
        return if version.nil? || version.empty?

        csv = CSV.generate_line([name, version, license], force_quotes: true)
        IO.write(data_file_for(name), csv, mode: 'a')
      end
    end
  end
end
