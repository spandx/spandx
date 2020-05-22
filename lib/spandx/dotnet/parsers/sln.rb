# frozen_string_literal: true

module Spandx
  module Dotnet
    module Parsers
      class Sln < ::Spandx::Core::Parser
        def match?(path)
          path.extname == '.sln'
        end

        def parse(path)
          project_paths_from(path).map do |project_path|
            ::Spandx::Core::Parser.parse(project_path)
          end.flatten
        end

        private

        def project_paths_from(path)
          path.each_line.map do |line|
            next unless project_line?(line)

            project_path = project_path_from(line)
            next unless project_path

            path.dirname.join(project_path).cleanpath.to_path
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
