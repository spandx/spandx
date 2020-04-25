# frozen_string_literal: true

module Spandx
  module Dotnet
    class Index
      DEFAULT_DIR = File.expand_path(File.join(Dir.home, '.local', 'share', 'spandx'))
      attr_reader :directory, :name, :gateway

      def initialize(directory: DEFAULT_DIR, gateway: Spandx::Dotnet::NugetGateway.new)
        @directory = directory ? File.expand_path(directory) : DEFAULT_DIR
        @name = 'nuget'
        @gateway = gateway
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
        path = data_file_for(name)
        FileUtils.mkdir_p(File.dirname(path))
        puts 'write: ' + path
        puts csv.inspect
        IO.write(path, csv, mode: 'a')
      end
    end
  end
end
