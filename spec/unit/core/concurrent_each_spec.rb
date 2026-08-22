# frozen_string_literal: true

RSpec.describe Spandx::Core::ConcurrentEach do
  subject { gateway_class.new }

  let(:gateway_class) { gateway_yielding(%w[a b c]) { |name| [[name, '1.0', ["#{name}-license"]]] } }

  # A gateway whose `each_package` yields `items` and whose `resolve` runs `block`.
  def gateway_yielding(items, &block)
    Class.new do
      include Spandx::Core::ConcurrentEach

      define_method(:initialize) { |http: nil| @http = http }
      define_method(:each_package) { |&blk| items.each { |item| blk.call(item) } }
      define_method(:resolve) { |_worker, item| block.call(item) }
    end
  end

  def resolve_all(gateway, concurrency: 2)
    [].tap { |acc| gateway.each(concurrency:) { |*record| acc << record } }
  end

  # Teardown is asynchronous, so sampling once after a fixed sleep races it --
  # and `Timeout.timeout` leaves a helper thread of its own behind, which makes
  # a bare count depend on spec ordering. Wait for the threads to go instead.
  def threads_after_teardown(target, timeout: 30)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
    sleep 0.02 while Thread.list.size > target && Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
    Thread.list.size
  end

  describe '#each' do
    it 'yields every resolved record' do
      expect(resolve_all(subject)).to match_array([
        ['a', '1.0', ['a-license']],
        ['b', '1.0', ['b-license']],
        ['c', '1.0', ['c-license']],
      ])
    end

    context 'when resolve returns more than one record per item' do
      let(:gateway_class) do
        gateway_yielding(['monolog']) { |name| [[name, '1.0', ['MIT']], [name, '2.0', ['MIT']]] }
      end

      it 'yields each of them' do
        expect(resolve_all(subject)).to match_array([
          ['monolog', '1.0', ['MIT']],
          ['monolog', '2.0', ['MIT']],
        ])
      end
    end

    context 'when resolve returns no records for an item' do
      let(:gateway_class) do
        gateway_yielding(%w[a b]) { |name| name == 'a' ? [] : [[name, '1.0', []]] }
      end

      it 'skips it' do
        expect(resolve_all(subject)).to eql([['b', '1.0', []]])
      end
    end

    # A worker that dies used to leave the stop sentinel un-enqueued, so the
    # consumer blocked on the queue for good.
    context 'when resolve raises for one item' do
      let(:gateway_class) do
        gateway_yielding(%w[a b c]) do |name|
          raise 'boom' if name == 'b'

          [[name, '1.0', ['MIT']]]
        end
      end

      it 'still yields the records that succeeded, without hanging' do
        expect(resolve_all(subject)).to match_array([
          ['a', '1.0', ['MIT']],
          ['c', '1.0', ['MIT']],
        ])
      end
    end

    context 'when resolve raises for every item' do
      let(:gateway_class) { gateway_yielding(%w[a b]) { |_name| raise 'boom' } }

      it 'completes instead of hanging' do
        expect(resolve_all(subject)).to be_empty
      end
    end

    # A worker wedged in an un-timed-out syscall -- a DNS lookup, in the run
    # that prompted this -- used to block `ThreadPool#shutdown`'s join, so the
    # stop sentinel was never enqueued and the consumer waited for good.
    context 'when resolve blocks forever for one item' do
      let(:gateway_class) do
        gateway_yielding(%w[a b c]) do |name|
          Queue.new.pop if name == 'b'

          [[name, '1.0', ['MIT']]]
        end
      end

      before { stub_const('Spandx::Core::ThreadPool::SHUTDOWN_TIMEOUT', 1) }

      it 'yields the records that finished, without waiting on the stuck worker' do
        records = Timeout.timeout(20) { resolve_all(subject) }

        expect(records).to match_array([
          ['a', '1.0', ['MIT']],
          ['c', '1.0', ['MIT']],
        ])
      end
    end

    it 'does not leak threads when the caller stops early' do
      before_count = Thread.list.size
      seen = 0
      subject.each(concurrency: 2) do |*_record|
        seen += 1
        break if seen.positive?
      end

      expect(threads_after_teardown(before_count)).to be <= before_count
    end

    # The result queue is bounded, so stopping early leaves producers blocked
    # in `enq` rather than merely idle. They still have to be torn down.
    context 'when the caller stops early with the queue saturated' do
      let(:gateway_class) do
        gateway_yielding((1..500).map(&:to_s)) { |name| [[name, '1.0', ['MIT']]] }
      end

      it 'does not leak threads' do
        before_count = Thread.list.size
        seen = 0
        subject.each(concurrency: 2) do |*_record|
          seen += 1
          break if seen.positive?
        end

        expect(threads_after_teardown(before_count)).to be <= before_count
      end
    end
  end
end
