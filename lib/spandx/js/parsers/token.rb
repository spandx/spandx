# frozen_string_literal: true

module Spandx
  module Js
    module Parsers
      class Token
        attr_accessor :type, :value

        def initialize(type, value)
          @type = type
          @value = value
        end
      end
    end
  end
end
