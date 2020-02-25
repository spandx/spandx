# frozen_string_literal: true

module Spandx
  class OfflineIndex
    attr_reader :db

    def initialize(package_manager)
      @db = Spandx::Database.new(url: "https://github.com/mokhan/spandx-#{package_manager}.git")
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
      path = datafile_for(name)
      lines = lines_in(path)

      search_key = "#{name}-#{version}"
      db.open(path) do |io|
        until lines.empty?
          if lines.size == 1
            io.seek(lines[0])
            row = CSV.parse(io.readline)[0]
            comparison = search_key <=> "#{row[0]}-#{row[1]}"
            return comparison.zero? ? row : nil
          end

          mid = lines.size / 2
          io.seek(lines[mid])
          row = CSV.parse(io.readline)[0]

          comparison = search_key <=> "#{row[0]}-#{row[1]}"
          return row if comparison.zero?

          lines = comparison > 0 ? lines.slice(mid + 1, lines.length) : lines.slice(0, mid)
        end
      end
    end

    def datafile_for(name)
      "lib/spandx/rubygems/index/#{key_for(name)}/data"
    end

    def lines_in(file)
      lines = []
      db.open(file) do |io|
        until io.eof?
          lines << io.pos
          io.gets
        end
      end
      lines
    end
  end
end
