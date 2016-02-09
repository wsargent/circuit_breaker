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

  def trip
    raise invalid_transition_exception("trip") unless can_transition_to?(:open)
    @state = :open
  end

  def trip!
    trip
  end

  def attempt_reset
    raise invalid_transition_exception("attempt_reset") unless can_transition_to?(:half_open)
    @state = :half_open
  end

  def reset
    raise invalid_transition_exception("reset") unless can_transition_to?(:closed)
    @state = :closed
    reset_failure_count
  end

  # if AASM is required elsewhere it will call this method to get current state
  def aasm(_)
    OpenStruct.new(current_state: @state)
  end

  def initialize()
    @failure_count = 0
    @last_failure_time = nil
    @state = :closed
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

  private

  attr_reader :state

  def can_transition_to?(to_state)
    TRANSITIONS[to_state].include?(state)
  end

  def invalid_transition_exception(event_name)
    invalid_transition_exception_class.new(self, event_name, "circuit_state")
  end

  def invalid_transition_exception_class
    aasm_exception_defined? ? aasm_exception_class : default_exception_class
  end

  def aasm_exception_defined?
    @aasm_exception_defined ||= begin
      aasm_exception_class
      true
    rescue NameError
      false
    end
  end

  def aasm_exception_class
    AASM::InvalidTransition
  end

  def default_exception_class
    CircuitBreaker::InvalidTransition
  end
end

