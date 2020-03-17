# frozen_string_literal: true

module Spandx
  module Rubygems
    class OfflineIndex
      attr_reader :db

      def initialize(package_manager)
        @package_manager = package_manager
        @db = ::Spandx::Core::Database.new(url: "https://github.com/mokhan/spandx-#{package_manager}.git")
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
        db.open(datafile_for(name)) do |io|
          search_for("#{name}-#{version}", io, lines_in(io))
        end
      rescue Errno::ENOENT => error
        Spandx.logger.error(error)
        nil
      end

      def datafile_for(name)
        ".index/#{key_for(name)}/#{@package_manager}"
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

        mid = lines.size == 1 ? 0 : lines.size / 2
        io.seek(lines[mid])
        comparison = matches?(term, parse_row(io)) { |row| return row }
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
        CSV.parse(io.readline)[0]
      end
    end
  end
end
