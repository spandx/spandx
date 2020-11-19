# frozen_string_literal: true

module Spandx
  module Core
    class Git
      attr_reader :root, :url, :default_branch

      def initialize(url:, default_branch: 'main')
        @url = url
        @default_branch = default_branch
        @root = path_for(url)
      end

      def read(path)
        full_path = root.join(path)
        full_path.read if full_path.exist?
      end

      def update!
        dotgit? ? pull! : clone!
      end

      private

      def path_for(url)
        uri = URI.parse(url)
        name = uri.path.gsub(/\.git$/, '')
        Pathname(File.expand_path(File.join(Dir.home, '.local', 'share', name)))
      end

      def dotgit?
        root.join('.git').directory?
      end

      def clone!(branch: default_branch)
        system('rm', '-rf', root.to_s, exception: true) if root.exist?
        system('git', 'clone', '--quiet', '--depth=1', '--single-branch', '--branch', branch, url, root.to_s, exception: true)
      end

      def pull!(remote: 'origin', branch: default_branch)
        Dir.chdir(root) do
          system('git', 'fetch', '--quiet', '--depth=1', '--prune', '--no-tags', remote, exception: true)
          system('git', 'checkout', '--quiet', branch, exception: true)
        end
      end
    end
  end
end
