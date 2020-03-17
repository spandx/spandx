# frozen_string_literal: true

module Spandx
  module Core
    class Report
      FORMATS = {
        json: :to_json,
        hash: :to_h,
      }

      def initialize
        @dependencies = []
      end

      def add(dependency)
        @dependencies.push(dependency)
      end

      def to(format)
        self.public_send(FORMATS.fetch(format.to_sym, :to_json))
      end

      def to_h
        { version: '1.0', dependencies: [] }.tap do |report|
          @dependencies.each do |dependency|
            report[:dependencies].push(dependency.to_h)
          end
        end
      end

      def to_json(*_args)
        JSON.pretty_generate(to_h)
      end
    end
  end
end
