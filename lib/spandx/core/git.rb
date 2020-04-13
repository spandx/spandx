# frozen_string_literal: true

module Spandx
  module Core
    class Git
      attr_reader :path, :url

      def initialize(url:)
        @url = url
        @path = path_for(url)
      end

      def update!
        dotgit? ? pull! : clone!
      end

      def expand_path(relative_path)
        File.join(path, relative_path)
      end

      def read(path)
        update! unless dotgit?

        full_path = expand_path(path)
        IO.read(full_path) if File.exist?(full_path)
      end

      def open(path, mode: 'r')
        update! unless dotgit?

        File.open(expand_path(path), mode) do |io|
          yield io
        end
      end

      private

      def path_for(url)
        uri = URI.parse(url)
        name = uri.path.gsub(/\.git$/, '')
        File.expand_path(File.join(Dir.home, '.local', 'share', name))
      end

      def dotgit?
        File.directory?(File.join(path, '.git'))
      end

      def clone!
        system('git', 'clone', '--quiet', url, path)
      end

      def pull!
        within do
          system('git', 'pull', '--no-rebase', '--quiet', 'origin', 'master')
        end
      end

      def within
        Dir.chdir(path) do
          yield
        end
      end
    end
  end
end
