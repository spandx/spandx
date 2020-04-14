# frozen_string_literal: true

module Spandx
  module Core
    class Report
      include Enumerable

      FORMATS = {
        csv: :to_csv,
        hash: :to_h,
        json: :to_json,
        table: :to_table,
      }.freeze

      def initialize
        @dependencies = SortedSet.new
      end

      def add(dependency)
        @dependencies << dependency
      end

      def each
        @dependencies.each do |dependency|
          yield dependency
        end
      end

      def to(format, formats: FORMATS)
        public_send(formats.fetch(format&.to_sym, :to_json))
      end

      def to_table
        Table.new do |table|
          map do |dependency|
            table << dependency
          end
        end
      end

      def to_h
        { version: '1.0', dependencies: [] }.tap do |report|
          each do |dependency|
            report[:dependencies].push(dependency.to_h)
          end
        end
      end

      def to_json(*_args)
        JSON.pretty_generate(to_h)
      end

      def to_csv
        map do |dependency|
          CSV.generate_line(dependency.to_a)
        end
      end
    end
  end
end
