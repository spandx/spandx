# frozen_string_literal: true

module Spandx
  class Guess
    def self.license_for(content)
      Licensee::ProjectFiles::LicenseFile.new(content).license.key.upcase
    end
  end
end
