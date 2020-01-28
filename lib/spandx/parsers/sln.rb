module Spandx
  module Parsers
    class Sln
      def parse(file_path)
        IO.read(file_path)
        []
      end
    end
  end
end
