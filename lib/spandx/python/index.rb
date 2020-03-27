# frozen_string_literal: true

module Spandx
  module Python
    class Index
      include Enumerable

      attr_reader :directory, :name, :source

      def initialize(directory:)
        @directory = directory
        @name = 'pypi'
        @source = 'https://pypi.org'
        Thread.abort_on_exception = true
      end

      def update!(catalogue:, output:)
        queue = Queue.new
        [
          fetch(queue, output),
          save(queue, output, catalogue)
        ].each(&:join)
      end

      def each
        each_package { |x| yield x }
      end

      private

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

      def fetch(queue, output)
        Thread.new do
          each do |dependency|
            output.puts "Queue: #{dependency[:name]}"
            queue.enq(dependency)
          end
          queue.enq(:stop)
        end
      end

      def save(queue, output, catalogue)
        Thread.new do
          loop do
            item = queue.deq
            break if item == :stop

            output.puts "Save: #{item[:name]}"
            insert!(item, catalogue)
          end
        end
      end

      def insert!(dependency, catalogue)
        [catalogue.object_id, dependency].inspect
      end
    end
  end
end
