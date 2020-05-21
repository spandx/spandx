# frozen_string_literal: true

module Spandx
  module Core
    class Spinner
      NULL = Class.new do
        def self.spin(*args); end

        def self.stop(*args); end
      end

      attr_reader :columns, :spinner

      def initialize(columns: TTY::Screen.columns, output: $stderr)
        @columns = columns
        @spinner = Nanospinner.new(output)
        @queue = Queue.new
        @thread = Thread.new { work }
      end

      def spin(message)
        @queue.enq(justify(message))
        yield if block_given?
      end

      def stop
        @queue.clear
        @queue.enq(:stop)
        @thread.join
      end

      private

      def justify(message)
        message.to_s.ljust(columns - 3)
      end

      def work
        last_message = justify('')
        loop do
          message = @queue.empty? ? last_message : @queue.deq
          break if message == :stop

          spinner.spin(message)
          last_message = message
          sleep 0.1
        end
      end
    end
  end
end
