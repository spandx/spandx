# frozen_string_literal: true

module Spandx
  module Python
    class Index
      include Enumerable

      attr_reader :directory, :name, :pypi, :source

      def initialize(directory:)
        @directory = directory
        @name = 'pypi'
        @source = 'https://pypi.org'
        @pypi = Pypi.new
        Thread.abort_on_exception = true
      end

      def update!(*)
        queue = Queue.new
        [fetch(queue), save(queue)].each(&:join)
      end

      def each
        each_package { |x| yield x }
      end

      private

      def files(pattern)
        Dir.glob(pattern, base: directory).sort.each do |file|
          fullpath = File.join(directory, file)
          yield fullpath unless File.directory?(fullpath)
        end
      end

      def sort_index!
        files('**/pypi') do |path|
          IO.write(path, IO.readlines(path).sort.join)
        end
      end

      def each_package(url = "#{source}/simple/")
        html = Nokogiri::HTML(Spandx.http.get(url).body)
        html.css('a[href*="/simple"]').each do |node|
          each_version("#{source}/#{node.attribute('href').value}") do |version|
            yield version
          end
        end
      end

      def each_version(url)
        html = Nokogiri::HTML(Spandx.http.get(url).body)
        name = html.css('h1')[0].content.gsub('Links for ', '')
        html.css('a').each do |node|
          yield({ name: name, version: version_from(node.attribute('href').value) })
        end
      end

      def version_from(url)
        _name, version, _rest = url.split('/')[-1].split('#')[0].split('-')
        version
      end

      def fetch(queue)
        Thread.new do
          each do |dependency|
            queue.enq(dependency)
          end
          queue.enq(:stop)
        end
      end

      def save(queue)
        Thread.new do
          loop do
            item = queue.deq
            break if item == :stop

            insert!(item[:name], item[:version])
          end
        end
      end

      def digest_for(components)
        Digest::SHA1.hexdigest(Array(components).join('/'))
      end

      def data_dir_for(name)
        File.join(directory, digest_for(name)[0...2].downcase)
      end

      def data_file_for(name)
        File.join(data_dir_for(name), 'pypi')
      end

      def insert!(name, version)
        definition = pypi.definition_for(name, version)
        license = definition['license']
        return if license.nil? || license.empty?

        csv = CSV.generate_line([name, version, license], force_quotes: true)
        IO.write(data_file_for(name), csv, mode: 'a')
      end
    end
  end
end
