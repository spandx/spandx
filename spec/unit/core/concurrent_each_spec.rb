# frozen_string_literal: true

RSpec.describe Spandx::Core::ConcurrentEach do
  subject { gateway_class.new }

  let(:gateway_class) do
    Class.new do
      include Spandx::Core::ConcurrentEach

      def initialize(http: nil)
        @http = http
      end

      def each
        yield('a', 1)
        yield('b', 2)
        yield('c', 3)
      end

      def resolve(_worker, name, multiplier)
        yield(name, multiplier, [multiplier * 2])
      end
    end
  end

  describe '#each_resolved' do
    it 'yields every resolved record' do
      resolved = []
      subject.each_resolved(concurrency: 2) { |name, multiplier, licenses| resolved << [name, multiplier, licenses] }

      expect(resolved).to match_array([
        ['a', 1, [2]],
        ['b', 2, [4]],
        ['c', 3, [6]],
      ])
    end

    context 'when resolve yields more than one record per item' do
      let(:gateway_class) do
        Class.new do
          include Spandx::Core::ConcurrentEach

          def initialize(http: nil)
            @http = http
          end

          def each
            yield('monolog')
          end

          def resolve(_worker, name)
            yield(name, '1.0', ['MIT'])
            yield(name, '2.0', ['MIT'])
          end
        end
      end

      it 'yields every resolved record' do
        resolved = []
        subject.each_resolved(concurrency: 2) { |name, version, licenses| resolved << [name, version, licenses] }

        expect(resolved).to match_array([
          ['monolog', '1.0', ['MIT']],
          ['monolog', '2.0', ['MIT']],
        ])
      end
    end
  end
end
