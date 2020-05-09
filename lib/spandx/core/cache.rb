# frozen_string_literal: true

module Spandx
  module Core
    class Cache
      attr_reader :package_manager, :root

      def initialize(package_manager, root: "#{Spandx.git[:cache].path}/.index")
        @package_manager = package_manager
        @root = root
      end

      def licenses_for(name, version)
        return [] if name.nil? || name.empty?

        found = datafile_for(name).search(name: name, version: version)
        Spandx.logger.debug { "Cache miss: #{name}-#{version}" } unless found
        found ? found[2].split('-|-') : []
      end

      def each
        datafiles.each do |_hex, datafile|
          datafile.each do |item|
            yield item
          end
        end
      end

      def insert(name, version, licenses)
        return if name.nil? || name.empty?

        datafile_for(name).insert(name, version, licenses)
      end

      def rebuild_index
        datafiles.each do |_hex, datafile|
          datafile.index!
        end
      end

      private

      def digest_for(name)
        Digest::SHA1.hexdigest(name)
      end

      def key_for(name)
        digest_for(name)[0...2]
      end

      def datafile_for(name)
        datafiles.fetch(key_for(name))
      end

      def datafiles
        @datafiles ||= candidate_keys.each_with_object({}) do |key, memo|
          memo[key] = Datafile.new(File.join(root, "#{key}/#{package_manager}"))
        end
      end

      def candidate_keys
        (0x00..0xFF).map { |x| x.to_s(16).upcase.rjust(2, '0').downcase }
      end
    end
  end
end
