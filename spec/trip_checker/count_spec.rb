require 'spec_helper'

describe CircuitBreaker::TripChecker::Count do
  subject { CircuitBreaker::TripChecker::Count.new(nil, 3) }
  StateDouble = Struct.new(:failure_count)

  describe '#tripped?' do
    it 'returns true if the value is over the threshold' do
      state = StateDouble.new(4)
      expect(subject.tripped?(state)).to be(true)
    end

    it 'returns false if the value is below the threshold' do
      state = StateDouble.new(2)
      expect(subject.tripped?(state)).to be(false)
    end
  end
end
