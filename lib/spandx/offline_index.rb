# frozen_string_literal: true

require 'csv'

module Spandx
  class OfflineIndex
    attr_reader :db

    def initialize(db)
      @db = db
    end

    def licenses_for(name:, version:)
      path = "lib/spandx/rubygems/index/#{key_for(name)}/data"
      csv = CSV.new(db.read(path))
      found = csv.find do |row|
        row[0] == name && row[1] == version
      end
      found[2].split('-|-')
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
