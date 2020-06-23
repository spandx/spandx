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

      def clone!
        system('rm', '-rf', root.to_s) if root.exist?
        system('git', 'clone', '--quiet', '--depth=1', '--single-branch', '--branch', 'master', url, root.to_s)
      end

      def pull!
        Dir.chdir(root) do
          system('git', 'pull', '--no-rebase', '--quiet', 'origin', 'master')
        end
      end
    end
  end
end
