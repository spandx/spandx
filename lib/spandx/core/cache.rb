# frozen_string_literal: true

module Spandx
  module Core
    class Cache
      attr_reader :package_manager, :root

      def initialize(package_manager, root: "#{Spandx.git[:cache].path}/.index")
        @package_manager = package_manager
        @cache = {}
        @lines = {}
        @root = root
      end

      def licenses_for(name, version)
        found = search(name: name, version: version)
        Spandx.logger.debug("Cache miss: #{name}-#{version}") if found.nil?
        found ? found[2].split('-|-') : []
      end

      def insert(name, version, licenses)
        return if name.nil? || name.empty?
        return if version.nil? || version.empty?

        open_file(datafile_for(name), mode: 'a') do |io|
          io.write(CSV.generate_line(
            [name, version, licenses.join('-|-')],
            force_quotes: true
          ))
        end
      end

      def rebuild_index
        sort_index!
      end

      def expand_path(relative_path)
        File.join(root, relative_path)
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
        open_file(datafile) do |io|
          lines = @lines.fetch(datafile) { |key| @lines[key] = lines_in(io) }
          search_for("#{name}-#{version}", io, lines)
        end
      rescue Errno::ENOENT => error
        Spandx.logger.error(error)
        nil
      end

      def datafile_for(name)
        "#{key_for(name)}/#{package_manager}"
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

      def open_file(path, mode: 'r')
        absolute_path = expand_path(path)
        FileUtils.mkdir_p(File.dirname(absolute_path))

        File.open(absolute_path, mode) do |io|
          yield io
        end
      end

      def sort_index!
        files("**/#{package_manager}") do |path|
          IO.write(path, IO.readlines(path).sort.join)
        end
      end

      def files(pattern)
        Dir.glob(File.join(root, pattern)).sort.each do |absolute_path|
          next if File.directory?(absolute_path)
          next unless File.exist?(absolute_path)

          yield absolute_path
        end
      end
    end
  end
end
