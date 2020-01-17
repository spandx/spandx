# frozen_string_literal: true

module Spandx
  class Report
    def initialize(report: { version: '1.0', packages: [] })
      @report = report
    end

    def add(name:, version:, licenses: [])
      @report[:packages].push(
        name: name,
        version: version,
        licenses: licenses.map(&:id)
      )
    end

    def to_h
      @report
    end

    def to_json(*_args)
      JSON.pretty_generate(to_h)
    end
  end
end
