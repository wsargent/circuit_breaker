#
# CircuitState is created individually for each object, and keeps
# track of how the object is doing and whether the object's circuit
# has tripped or not.
#
class CircuitBreaker::CircuitState
  STATES = %i(open half_open closed)

  #the state transition map, to: [:from]
  TRANSITIONS = {
    open: [:closed, :half_open],
    half_open: [:open],
    closed: [:open, :half_open]
  }

  # define #open?, :closed?, :half_open?
  STATES.each do |state|
    define_method("#{state}?") do
      @state == state
    end
  end

  #
  # Trips the circuit breaker into the open state where it will immediately fail.
  #
  def trip
    raise invalid_transition_exception("trip") unless can_transition_to?(:open)
    @state = :open
  end
  alias trip! trip

  #
  # Transitions from an open state to a half_open state.
  #
  def attempt_reset
    raise invalid_transition_exception("attempt_reset") unless can_transition_to?(:half_open)
    @state = :half_open
  end

  #
  # Close the circuit from an open or half open state.
  #
  def reset
    raise invalid_transition_exception("reset") unless can_transition_to?(:closed)
    @state = :closed
    reset_failure_count
  end

  # if AASM is required elsewhere it will call this method to get current state
  def aasm(*)
    OpenStruct.new(current_state: @state)
  end

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

  private

  attr_reader :state

  def can_transition_to?(to_state)
    TRANSITIONS[to_state].include?(state)
  end

  def invalid_transition_exception(event_name)
    invalid_transition_exception_class.new(self, event_name, "circuit_state")
  end

  def invalid_transition_exception_class
    CircuitBreaker::InvalidTransition
  end
end
