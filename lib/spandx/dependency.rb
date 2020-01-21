# frozen_string_literal: true

module Spandx
  class Dependency
    attr_reader :name, :version, :licenses

    def initialize(name:, version:, licenses: [])
      @name = name
      @version = version
      @licenses = licenses
    end

    def to_h
      {
        name: name,
        version: version,
        licenses: licenses.map(&:id)
      }
    end
  end
end
