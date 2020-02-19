# frozen_string_literal: true

module Spandx
  class OfflineIndex
    attr_reader :db

    def initialize(package_manager)
      @db = Spandx::Database.new(url: "https://github.com/mokhan/spandx-#{package_manager}.git")
    end

    def licenses_for(name:, version:)
      path = "lib/spandx/rubygems/index/#{key_for(name)}/data"

      csv = CSV.new(db.read(path))
      search_key = "#{name}-#{version}"
      found = csv.to_a.bsearch do |row|
        search_key <=> "#{row[0]}-#{row[1]}"
      end
      csv.close
      found ? found[2].split('-|-') : []
    end

    private

    def digest_for(components)
      Digest::SHA1.hexdigest(Array(components).join('/'))
    end

    def key_for(name)
      digest_for(name)[0...2]
    end
  end
end
