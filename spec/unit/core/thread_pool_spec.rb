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
  end
end
