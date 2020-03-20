# frozen_string_literal: true

module Spandx
  module Rubygems
    class Cache
      attr_reader :db, :package_manager

      def initialize(package_manager, url:)
        @package_manager = package_manager
        @db = ::Spandx::Core::Database.new(url: url)
        @cache = {}
        @lines = {}
      end

      def licenses_for(name:, version:)
        found = search(name: name, version: version)
        found ? found[2].split('-|-') : []
      end

      private

      def digest_for(components)
        Digest::SHA1.hexdigest(Array(components).join('/'))
      end

      def key_for(name)
        digest_for(name)[0...2]
      end

      def search(name:, version:)
        datafile = datafile_for(name)
        db.open(datafile) do |io|
          search_for("#{name}-#{version}", io, @lines.fetch(datafile) { |key| @lines[key] = lines_in(io) })
        end
      rescue Errno::ENOENT => error
        Spandx.logger.error(error)
        nil
      end

      def datafile_for(name)
        ".index/#{key_for(name)}/#{package_manager}"
      end

      def lines_in(io)
        lines = []
        io.seek(0)
        until io.eof?
          lines << io.pos
          io.gets
        end
        lines
      end

      def search_for(term, io, lines)
        return if lines.empty?
        return @cache[term] if @cache.key?(term)

        mid = lines.size == 1 ? 0 : lines.size / 2
        io.seek(lines[mid])
        comparison = matches?(term, parse_row(io)) do |row|
          return row
        end

        search_for(term, io, partition(comparison, mid, lines))
      end

      def matches?(term, row)
        (term <=> "#{row[0]}-#{row[1]}").tap do |comparison|
          yield row if comparison.zero?
        end
      end

      def partition(comparison, mid, lines)
        min, max = comparison.positive? ? [mid + 1, lines.length] : [0, mid]
        lines.slice(min, max)
      end

      def parse_row(io)
        row = CSV.parse(io.readline)[0]
        @cache["#{row[0]}-#{row[1]}"] = row
        row
      end
    end
  end
end
