# frozen_string_literal: true

module Spandx
  module Core
    class Git
      attr_reader :root, :url

      def initialize(url:)
        @url = url
        @root = path_for(url)
      end

      def read(path)
        full_path = File.join(root, path)

        IO.read(full_path) if File.exist?(full_path)
      end

      def update!
        dotgit? ? pull! : clone!
      end

      private

      def path_for(url)
        uri = URI.parse(url)
        name = uri.path.gsub(/\.git$/, '')
        File.expand_path(File.join(Dir.home, '.local', 'share', name))
      end

      def dotgit?
        File.directory?(File.join(root, '.git'))
      end

      def clone!
        system('git', 'clone', '--quiet', url, path)
      end

      def pull!
        Dir.chdir(root) do
          system('git', 'pull', '--no-rebase', '--quiet', 'origin', 'master')
        end
      end
    end

    Database = Git
  end
end
