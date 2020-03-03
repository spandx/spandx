# frozen_string_literal: true

module Spandx
  module Dotnet
    module Parsers
      class Sln < ::Spandx::Core::Parser
        def self.matches?(filename)
          filename.match?(/.*\.sln/)
        end

        def parse(file_path)
          project_paths_from(file_path).map do |path|
            ::Spandx::Parsers
              .for(path, catalogue: catalogue)
              .parse(path)
          end.flatten
        end

        private

        def project_paths_from(file_path)
          IO.readlines(file_path).map do |line|
            next unless project_line?(line)

            path = project_path_from(line)
            next unless path

            path = File.join(File.dirname(file_path), path)
            Pathname.new(path).cleanpath.to_path
          end.compact
        end

        def project_line?(line)
          line.match?(/^\s*Project\(/)
        end

        def project_path_from(line)
          path = line.split('"')[5]
          return unless path

          path = path.tr('\\', '/')
          path.match?(/\.[a-z]{2}proj$/) ? path : nil
        end
      end
    end
  end
end
