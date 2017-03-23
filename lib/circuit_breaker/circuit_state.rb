require 'aasm'

#
# CircuitState is created individually for each object, and keeps
# track of how the object is doing and whether the object's circuit
# has tripped or not.
#
class CircuitBreaker::CircuitState

  include AASM

  aasm.state :half_open

  aasm.state :open

  aasm.state :closed, :enter => :reset_failure_count

  aasm.initial_state :closed

  #
  # Trips the circuit breaker into the open state where it will immediately fail.
  #
  aasm.event :trip do
    transitions :to => :open, :from => [:closed, :half_open]
  end

  #
  # Transitions from an open state to a half_open state.
  #
  aasm.event :attempt_reset do
    transitions :to => :half_open, :from => [:open]
  end

  #
  # Close the circuit from an open or half open state.
  #
  aasm.event :reset do
    transitions :to => :closed, :from => [:open, :half_open]
  end

  def initialize()
    @failure_count = 0
    @last_failure_time = nil
    @call_count = 0
  end

  attr_accessor :last_failure_time

  attr_accessor :failure_count

  attr_accessor :call_count

  def increment_call_count
    @call_count += 1
  end

  def increment_failure_count
    self.failure_count = self.failure_count + 1
    self.last_failure_time = Time.now
  end

  def reset_failure_count
    self.failure_count = 0
  end

  def reset_counts
    reset_failure_count
    @call_count = 0
  end
end
