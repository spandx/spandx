# frozen_string_literal: true

module Spandx
  module Core
    class Report
      attr_reader :dependencies

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

      def to(format, formats: FORMATS)
        public_send(formats.fetch(format&.to_sym, :to_json))
      end

      def to_table
        Terminal::Table.new(headings: ['Name', 'Version', 'Licenses', 'Location']) do |t|
          dependencies.each do |d|
            t.add_row d.to_a
          end
        end
      end

      def to_h
        { version: '1.0', dependencies: [] }.tap do |report|
          dependencies.each do |dependency|
            report[:dependencies].push(dependency.to_h)
          end
        end
      end

      def to_json(*_args)
        Oj.dump(to_h)
      end

      def to_csv
        dependencies.map do |dependency|
          CSV.generate_line(dependency.to_a)
        end
      end
    end
  end
end
