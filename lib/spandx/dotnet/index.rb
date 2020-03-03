# frozen_string_literal: true

module Spandx
  module Dotnet
    class Index
      DEFAULT_DIR = File.expand_path(File.join(Dir.home, '.local', 'share', 'spandx'))
      attr_reader :directory

      def initialize(directory: DEFAULT_DIR)
        @directory = directory ? File.expand_path(directory) : DEFAULT_DIR
      end

      def update!(catalogue:, limit: nil)
        counter = 0
        gateway = Spandx::Dotnet::NugetGateway.new(catalogue: catalogue)
        gateway.each do |spec|
          next unless spec['licenseExpression']

          write([gateway.host, spec['id'], spec['version']], spec['licenseExpression'])

          if limit
            counter += 1
            break if counter > limit
          end
        end
      end

      def indexed?(key)
        File.exist?(data_file_for(digest_for(key)))
      end

      def read(key)
        open_data(digest_for(key), mode: 'r', &:read)
      end

      def write(key, data)
        return if data.nil? || data.empty?

        open_data(digest_for(key)) do |x|
          x.write(data)
        end
      end

      private

      def digest_for(components)
        Digest::SHA1.hexdigest(Array(components).join('/'))
      end

      def open_data(key, mode: 'w')
        FileUtils.mkdir_p(data_dir_for(key))
        File.open(data_file_for(key), mode) do |file|
          yield file
        end
      end

      def data_dir_for(index_key)
        File.join(directory, *index_key.scan(/../)).downcase
      end

      def data_file_for(key)
        File.join(data_dir_for(key), 'data')
      end

      def upsert!(spec)
        return unless spec['licenseExpression']

        write([host, spec['id'], spec['version']], spec['licenseExpression'])
      end
    end
  end
end
