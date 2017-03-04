require 'spec_helper'

describe CircuitBreaker::TripChecker::Percentage do
  subject { CircuitBreaker::TripChecker::Percentage.new(nil, 0.5) }
  StateDouble = Struct.new(:failure_count, :call_count)

  describe '#tripped?' do
    it 'returns true if the percentage is over the threshold' do
      state = StateDouble.new(5, 10)
      expect(subject.tripped?(state)).to be(false)

      state.call_count = 9
      expect(subject.tripped?(state)).to be(true)
    end

    it 'requires at least the minimum number of calls' do
      state = StateDouble.new(0, 2)
      expect(subject.tripped?(state)).to be(false)
    end
  end
end
