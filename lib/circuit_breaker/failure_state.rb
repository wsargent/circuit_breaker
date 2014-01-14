# encoding: utf-8

class CircuitBreaker::FailureState
  def initialize
    @failure_count     = 0
    @last_failure_time = nil
  end

  attr_accessor :last_failure_time

  attr_accessor :failure_count

  def increment_failure_count
    @failure_count     = @failure_count + 1
    @last_failure_time = Time.now
  end

  def reset_failure_count
    @failure_count = 0
  end
end