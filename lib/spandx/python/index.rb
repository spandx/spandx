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

      private

      def fetch(queue)
        Thread.new do
          pypi.each do |dependency|
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

            insert!(item[:name], item[:version], item[:license])
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

      def insert!(name, version, license)
        return if name.nil? || name.empty?
        return if version.nil? || version.empty?

        csv = CSV.generate_line([name, version, license], force_quotes: true)
        IO.write(data_file_for(name), csv, mode: 'a')
      end
    end
  end
end
