require 'aasm'

#
# CircuitState is created individually for each object, and keeps
# track of how the object is doing and whether the object's circuit
# has tripped or not.
#
class CircuitBreaker::CircuitState

  include AASM

  aasm_state :half_open

  aasm_state :open

  aasm_state :closed, :enter => :reset_failure_count

  aasm_initial_state :closed

  #
  # Trips the circuit breaker into the open state where it will immediately fail.
  #
  aasm_event :trip do
    transitions :to => :open, :from => [:closed, :half_open]
  end

  #
  # Transitions from an open state to a half_open state.
  #
  aasm_event :attempt_reset do
    transitions :to => :half_open, :from => [:open]
  end

  #
  # Close the circuit from an open or half open state.
  #
  aasm_event :reset do
    transitions :to => :closed, :from => [:open, :half_open]
  end

  def initialize()
    @failure_count = 0
    @last_failure_time = nil
  end

  attr_accessor :last_failure_time

  attr_accessor :failure_count

  def increment_failure_count
    @failure_count = @failure_count + 1
    @last_failure_time = Time.now
  end

  def reset_failure_count
    @failure_count = 0
  end
  
end

