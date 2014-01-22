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

  def initialize(failure_state = CircuitBreaker::FailureState.new)
    @failure_state = failure_state
  end

  attr_reader :failure_state

  def last_failure_time
    failure_state.last_failure_time
  end

  def last_failure_time=(value)
    failure_state.last_failure_time = value
  end

  def failure_count
    failure_state.failure_count
  end

  def failure_count=(value)
    failure_state.failure_count = value
  end

  def increment_failure_count
    failure_state.increment_failure_count
  end

  def reset_failure_count
    failure_state.reset_failure_count
  end

  def current_state
    aasm.current_state
  end

end

