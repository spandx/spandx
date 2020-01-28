module Spandx
  module Parsers
    class Sln < Base
      def parse(file_path)
        paths = IO.readlines(file_path).map do |line|
          next unless line.match?(/^\s*Project\(/)

          path = line.split('"')[5]
          next unless path

          path = path.tr("\\", "/")
          next unless path.match?(/\.[a-z]{2}proj$/)

          dir = File.dirname(file_path)
          path = File.join(dir, path)
          Pathname.new(path).cleanpath.to_path
        end.compact
        paths.map do |path|
          parser = Parsers.for(path, catalogue: catalogue)
          parser.parse(path)
        end.flatten
      end

      private
    end
  end
end
