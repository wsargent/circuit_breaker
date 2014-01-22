require 'timeout'
require 'pry'

#
#
# CircuitHandler is stateless,
# so the circuit_state gets mixed in with the calling object.
#
#
class CircuitBreaker::CircuitHandler

  class NullLogger
    def debug(*args)
    end
  end

  #
  # The number of failures needed to trip the breaker.
  #
  attr_accessor :failure_threshold

  #
  # The period of time in seconds before attempting to reset the breaker.
  #
  attr_accessor :failure_timeout

  #
  # The period of time the circuit_method has to return before a timeout exception is thrown.
  #
  attr_accessor :invocation_timeout

  #
  # The exceptions which should be ignored if happens, they are not counted as failures
  #
  attr_accessor :excluded_exceptions

  #
  # Optional logger.
  #
  attr_accessor :logger

  DEFAULT_FAILURE_THRESHOLD  = 5
  DEFAULT_FAILURE_TIMEOUT    = 5
  DEFAULT_INVOCATION_TIMEOUT = 30
  DEFAULT_EXCLUDED_EXCEPTIONS= []

  def initialize(logger = NullLogger.new)
    @logger              = logger
    @failure_threshold   = DEFAULT_FAILURE_THRESHOLD
    @failure_timeout     = DEFAULT_FAILURE_TIMEOUT
    @invocation_timeout  = DEFAULT_INVOCATION_TIMEOUT
    @excluded_exceptions = DEFAULT_EXCLUDED_EXCEPTIONS
  end

  #
  # Returns a new CircuitState instance.
  #
  def new_circuit_state
    ::CircuitBreaker::CircuitState.new
  end

  #
  # Handles the method covered by the circuit breaker.
  #
  def handle(circuit_state, method, *args, &block)
    if is_tripped(circuit_state)
      @logger.debug("handle: breaker is tripped, refusing to execute: #{circuit_state.inspect}")
      on_circuit_open(circuit_state)
    end

    begin
      out = nil
      Timeout.timeout(@invocation_timeout, CircuitBreaker::CircuitBrokenException) do
        out = method.call(*args, &block)
        on_success(circuit_state)
      end
    rescue Exception => e
      on_failure(circuit_state) unless @excluded_exceptions.include?(e.class)
      raise
    end
    return out
  end

  #
  # Returns true when the number of failures is sufficient to trip the breaker, false otherwise.
  #
  def is_failure_threshold_reached(circuit_state)
    out = (circuit_state.failure_count > failure_threshold)
    @logger.debug("is_failure_threshold_reached=#{out}: #{circuit_state.failure_count} > #{failure_threshold}")

    return out
  end

  #
  # Returns true if enough time has elapsed since the last failure time, false otherwise.
  #
  def attempt_reset?(circuit_state)
    return false unless circuit_state.open?

    now = Time.now

    time_since    = now - circuit_state.last_failure_time
    attempt_reset = time_since >= failure_timeout

    @logger.debug("attempt_reset?=#{attempt_reset} #{attempt_reset ? 'timeout_exceeded' : 'timeout_still_in_progress'}:  time since last failure=#{time_since.inspect}")

    attempt_reset
  end

  #
  # Returns true if the circuit breaker is still open and the timeout has
  # not been exceeded, false otherwise.
  #
  def is_tripped(circuit_state)

    if attempt_reset?(circuit_state)
      @logger.debug("is_tripped: attempting reset into half open state for #{circuit_state.inspect}")
      circuit_state.attempt_reset
    end

    return circuit_state.open?
  end

  #
  # Called when an individual success happens.
  #
  def on_success(circuit_state)
    @logger.debug("on_success: #{circuit_state.inspect}")

    if circuit_state.closed?
      @logger.debug("on_success: state=closed reset_failure_count #{circuit_state.inspect}")
      circuit_state.reset_failure_count
    end

    if circuit_state.half_open?
      @logger.debug("on_success: state=half_open reset #{circuit_state.inspect}")
      circuit_state.reset
    end
  end

  #
  # Called when an individual failure happens.
  #
  def on_failure(circuit_state)
    current_state = circuit_state.current_state

    @logger.debug("on_failure: state=#{current_state}: #{circuit_state.inspect}")

    circuit_state.increment_failure_count

    if is_failure_threshold_reached(circuit_state) || circuit_state.half_open?
      # Set us into a closed state.
      @logger.debug("on_failure: state=#{current_state} tripping circuit breaker #{circuit_state.inspect}")
      circuit_state.trip
    end
  end

  #
  # Called when a call is made and the circuit is open.   Raises a CircuitBrokenException exception.
  #
  def on_circuit_open(circuit_state)
    @logger.debug("on_circuit_open: raising for #{circuit_state.inspect}")

    raise CircuitBreaker::CircuitBrokenException.new('Circuit broken, please wait for timeout', circuit_state)
  end
end
