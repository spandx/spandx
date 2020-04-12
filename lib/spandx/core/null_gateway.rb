# frozen_string_literal: true

module Spandx
  module Core
    class NullGateway
      def licenses_for(*_args)
        []
      end
    end
  end
end
