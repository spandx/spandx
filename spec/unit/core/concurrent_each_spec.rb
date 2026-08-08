# frozen_string_literal: true

RSpec.describe Spandx::Core::ConcurrentEach do
  subject { gateway_class.new }

  let(:gateway_class) { gateway_yielding(%w[a b c]) { |name| [[name, '1.0', ["#{name}-license"]]] } }

  # A gateway whose `each` yields `items` and whose `resolve` runs `block`.
  def gateway_yielding(items, &block)
    Class.new do
      include Spandx::Core::ConcurrentEach

      define_method(:initialize) { |http: nil| @http = http }
      define_method(:each) { |&blk| items.each { |item| blk.call(item) } }
      define_method(:resolve) { |_worker, item| block.call(item) }
    end
  end

  def resolve_all(gateway, concurrency: 2)
    [].tap { |acc| gateway.each_resolved(concurrency:) { |*record| acc << record } }
  end

  describe '#each_resolved' do
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

    it 'does not leak threads when the caller stops early' do
      before_count = Thread.list.size
      seen = 0
      subject.each_resolved(concurrency: 2) do |*_record|
        seen += 1
        break if seen.positive?
      end
      sleep 0.2

      expect(Thread.list.size).to be <= before_count
    end
  end
end
