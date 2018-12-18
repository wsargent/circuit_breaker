#
# CircuitState is created individually for each object, and keeps
# track of how the object is doing and whether the object's circuit
# has tripped or not.
#
class CircuitBreaker::CircuitState
  def initialize
    @failure_count = 0
    @last_failure_time = nil
    @call_count = 0
    @state = :closed
  end

  attr_accessor :last_failure_time

  attr_accessor :failure_count

  attr_accessor :call_count

  def increment_call_count
    @call_count += 1
  end

  def increment_failure_count
    @failure_count = @failure_count + 1
    @last_failure_time = Time.now
  end

  def reset_failure_count
    @failure_count = 0
  end

  def reset_counts
    reset_failure_count
    @call_count = 0
  end

  def current_state
    @state
  end

  # define #open?, :closed?, :half_open?
  STATES = %i(open half_open closed).each do |state|
    define_method("#{state}?") do
      @state == state
    end
  end

  #the state transition map, to: [:from]
  TRANSITIONS = {
    trip: { open: [:closed, :half_open] },
    attempt_reset: { half_open: [:open] },
    reset: { closed: [:open, :half_open] },
  }

  #
  # Trips the circuit breaker into the open state where it will immediately fail.
  #
  def trip
    fail invalid_transition_exception("trip") unless can_transition_to?(:trip, :open, current_state)
    @state = :open
  end
  alias trip! trip

  #
  # Transitions from an open state to a half_open state.
  #
  def attempt_reset
    fail invalid_transition_exception("attempt_reset") unless can_transition_to?(:attempt_reset, :half_open, current_state)
    @state = :half_open
  end

  #
  # Close the circuit from an open or half open state.
  #
  def reset
    fail invalid_transition_exception("reset") unless can_transition_to?(:reset, :closed, current_state)
    @state = :closed
    reset_failure_count
  end

  private

  attr_reader :state

  def can_transition_to?(transition, to_state, from_state)
    TRANSITIONS.fetch(transition).fetch(to_state).include?(from_state)
  end

  def invalid_transition_exception(event_name)
    invalid_transition_exception_class.new(self, event_name, "circuit_state")
  end

  def invalid_transition_exception_class
    CircuitBreaker::InvalidTransition
  end
end
