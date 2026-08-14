# frozen_string_literal: true

RSpec.describe Spandx::Core::ThreadPool do
  describe '.open' do
    it 'runs every queued job with its arguments splatted back out' do
      results = Queue.new

      described_class.open(size: 4) do |pool|
        10.times { |n| pool.run(n) { |x| results << (x * 2) } }
      end

      expect(Array.new(10) { results.pop }).to match_array((0..9).map { |x| x * 2 })
    end

    it 'waits for every job to finish before returning' do
      results = []

      described_class.open(size: 2) do |pool|
        5.times { |n| pool.run(n) { |x| results << x } }
      end

      expect(results).to match_array((0..4).to_a)
    end

    it 'keeps running after a job raises' do
      results = []

      described_class.open(size: 2) do |pool|
        5.times { |n| pool.run(n) { |x| x.zero? ? raise('boom') : results << x } }
      end

      expect(results).to match_array((1..4).to_a)
    end

    # A worker wedged in a syscall that never returns must not hold the pool
    # open; `shutdown` gives it a deadline and then abandons it.
    it 'gives up on a worker that never finishes' do
      finished = false

      described_class.open(size: 2, shutdown_timeout: 1) do |pool|
        pool.run { Queue.new.pop }
        pool.run { finished = true }
      end

      expect(finished).to be(true)
    end
  end

  describe '#run' do
    it 'applies backpressure once the queue is full' do
      pool = described_class.new(size: 1)
      release = Queue.new
      pool.run { release.pop }

      enqueued = Thread.new { (pool.instance_variable_get(:@queue).max + 2).times { pool.run { nil } } }
      blocked = enqueued.join(0.5).nil?

      release << :go
      enqueued.join(5)
      pool.shutdown

      expect(blocked).to be(true)
    end
  end
end
