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
        @dependencies = []
      end

      def add(dependency)
        @dependencies.push(dependency)
      end

      def each
        @dependencies.sort.each do |dependency|
          yield dependency
        end
      end

      def to(format)
        public_send(FORMATS.fetch(format&.to_sym, :to_json))
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

    class Table
      def initialize
        @rows = []
        @max_justification = 0
        yield self
      end

      def <<(item)
        row = item.to_a
        new_max = row[0].size
        @max_justification = new_max if new_max > @max_justification
        @rows << row
      end

      def to_s
        @rows.map do |row|
          row.each.with_index.map do |cell, index|
            justification = index.zero? ? @max_justification : 15
            Array(cell).join(', ').ljust(justification, ' ')
          end.join
        end
      end
    end
  end
end
