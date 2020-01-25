# frozen_string_literal: true

module Spandx
  module Parsers
    class Csproj
      PackageReference = Struct.new(:name, :version, keyword_init: true)
    end
  end
end
